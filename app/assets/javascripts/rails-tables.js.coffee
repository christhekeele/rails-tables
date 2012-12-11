$ ->
  $('table.datatable').bind 'sort', ->
    $(@).data('unsorted', false)
  $('table.datatable').one 'sort', ->
    $(@).data('unsorted', true)

@rails_tables = {}
@rails_tables.columns = (datatable)->
  for column, order of $(datatable).data() when /_ordering/.test(column)
    {asSorting: [ order ], aTargets: [ column.substring(0, column.length - "_ordering".length) ]}
@rails_tables.params = (datatable) ->
  (aoData) ->
    aoData.push
      name: 'bUseDefaultSort', value: if $(datatable).data('unsorted') then true else false