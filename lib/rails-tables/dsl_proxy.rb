class DslProxy < BasicObject
  
  # Pass in a builder-style class, or other receiver you want set as "self" within the
  # block, and off you go.  The passed block will be executed with all
  # block-context local and instance variables available, but with all
  # method calls sent to the receiver you pass in.  The block's result will
  # be returned.  
  #
  # If the receiver doesn't respond_to? a method, any missing methods
  # will be proxied to the enclosing context.
  def self.exec(receiver, &block) # :yields: receiver
    # Find the context within which the block was defined
    context = ::Kernel.eval('self', block.binding)

    # Create or re-use our proxy object
    if context.respond_to?(:_to_dsl_proxy)
      # If we're nested, we don't want/need a new dsl proxy, just re-use the existing one
      proxy = context._to_dsl_proxy
    else
      # Not nested, create a new proxy for our use
      proxy = DslProxy.new(context)
    end

    # Exec the block and return the result
    proxy._proxy(receiver, &block)
  end
  
  # Simple state setup
  def initialize(context)
    @_receivers = []
    @_instance_original_values = {}
    @_context = context
  end
  
  def _proxy(receiver, &block) # :yields: receiver
    # Sanity!
    raise 'Cannot proxy with a DslProxy as receiver!' if receiver.respond_to?(:_to_dsl_proxy)
    
    if @_receivers.empty?
      # On first proxy call, run each context instance variable, 
      # and set it to ourselves so we can proxy it
      @_context.instance_variables.each do |var|
        unless var.to_s.starts_with?('@_')
          value = @_context.instance_variable_get(var.to_s)
          @_instance_original_values[var] = value
          #instance_variable_set(var, value)
          instance_eval "#{var} = value"
        end
      end
    end

    # Save the dsl target as our receiver for proxying
    _push_receiver(receiver)

    # Run the block with ourselves as the new "self", passing the receiver in case
    # the code wants to disambiguate for some reason
    result = instance_exec(@_receivers.last, &block)
    
    # Pop the last receiver off the stack
    _pop_receiver
    
    if @_receivers.empty?
      # Run each local instance variable and re-set it back to the context if it has changed during execution
      #instance_variables.each do |var|
      @_context.instance_variables.each do |var|
        unless var.to_s.starts_with?('@_')
          value = instance_eval("#{var}")
          #value = instance_variable_get("#{var}")
          if @_instance_original_values[var] != value
            @_context.instance_variable_set(var.to_s, value)
          end
        end
      end
    end
    
    return result
  end
  
  # For nesting multiple proxies
  def _to_dsl_proxy
    self
  end
  
  # Set the currently active receiver
  def _push_receiver(receiver)
    @_receivers.push receiver
  end
  
  # Remove the currently active receiver, restore old receiver if nested
  def _pop_receiver
    @_receivers.pop
  end

  # Proxies all calls to our receiver, or to the block's context
  # if the receiver doesn't respond_to? it.
  def method_missing(method, *args, &block)
    #$stderr.puts "Method missing: #{method}"
    if @_receivers.last.respond_to?(method)
      #$stderr.puts "Proxy [#{method}] to receiver"
      @_receivers.last.__send__(method, *args, &block)
    else
      #$stderr.puts "Proxy [#{method}] to context"
      @_context.__send__(method, *args, &block)
    end
  end
  
  # Let anyone who's interested know what our proxied objects will accept
  def respond_to?(method, include_private = false)
    return true if method == :_to_dsl_proxy
    @_receivers.last.respond_to?(method, include_private) || @_context.respond_to?(method, include_private)
  end
  
  # Proxies searching for constants to the context, so that eg Kernel::foo can actually
  # find Kernel - BasicObject does not partake in the global scope!
  def self.const_missing(name)
    #$stderr.puts "Constant missing: #{name} - proxy to context"
    @_context.class.const_get(name)
  end
  
end