$ ->
  $('table.datatable th.th-sortable.sorting').unbind 'click'
  $('table.datatable th.sorting').click ->
    console.log "EVENT"
    $(@).closest('table.datatable').data('unsorted', false)

@rails_tables = {}
@rails_tables.columns = ->
  for column, order of $(@).data() when /_ordering/.test(column)
    asSorting: [ order ], aTargets: [ column.substring(0, column.length - "_ordering".length) ]

@rails_tables.params = (aoData) ->
  aoData.push
    name: 'bUseDefaultSort', value: if $(@).data('unsorted') then true else false

