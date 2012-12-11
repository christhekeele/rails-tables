$ ->
  $('table.datatable').bind 'sort', ->
    $(@).data('unsorted', false)
  $('table.datatable').one 'sort', ->
    $(@).data('unsorted', true)

@rails_tables = {}
@rails_tables.params = (datatable) ->
  (aoData) ->
    aoData.push
      name: 'bUseDefaultSort', value: if $(datatable).data('unsorted') then true else false