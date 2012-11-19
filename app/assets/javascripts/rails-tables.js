$ ->
  $('table.datatable').each ->
    ordering_options = for column, order of $(@).data() when /_ordering/.test(column)
      asSorting: [ order ], aTargets: [ column.substring(0, column.length - "_ordering".length) ]

    $(@).dataTable
      aoColumnDefs: ordering_options
      fnServerParams: (aoData)->
        aoData.push
          name: 'bUseDefaultSort', value: if $(@).data('unsorted') then true else false

    $(@).find('.aria-sort').click ->
      $(@).parents('table.datatable').data('unsorted', false)