$ ->
  $('table.datatable').bind 'sort', ->
    $(@).data('unsorted', false)
  $('table.datatable').one 'sort', ->
    $(@).data('unsorted', true)

@rails_tables = {}
@rails_tables.columns = (datatable)->
  console.log $(datatable).data().order_column, $(datatable).data().order_direction
  asSorting: [ $(datatable).data().order_direction ], aTargets: [ $(datatable).data().order_column ]
@rails_tables.params = (datatable) ->
  (aoData) ->
    aoData.push
      name: 'bUseDefaultSort', value: if $(datatable).data('unsorted') then true else false