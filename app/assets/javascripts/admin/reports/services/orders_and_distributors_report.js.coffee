angular.module("admin.reports").factory 'OrdersAndDistributorsReport', (uiGridGroupingConstants, UIGridReport) ->
  new class OrdersAndDistributorsReport extends UIGridReport
    gridOptions: ->
      enableSorting: true
      enableFiltering: true
      enableGridMenu: true
      exporterMenuAllData: false
      exporterMenuVisibleData: false
      exporterPdfDefaultStyle: {fontSize: 6 }
      exporterPdfTableHeaderStyle: { fontSize: 5, bold: true }
      exporterPdfTableStyle: { width: 'auto'}
      exporterPdfMaxGridWidth: 600
      columnDefs: [
        { field: 'order.created_at',                    displayName: 'Order date',            width: '15%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @orderDateFinalizer }
        { field: 'order.id',                            displayName: 'Order ID',              width: '6%',  visible: true, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, grouping: { groupPriority: 21 } }
        { field: 'order.customer',                      displayName: 'Customer name',         width: '12%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @customerFinalizer }
        { field: 'order.email',                         displayName: 'Email',                 width: '20%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @customerEmailFinalizer }
        { field: 'order.bill_address.phone',            displayName: 'Phone',                 width: '12%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @customerPhoneFinalizer }
        { field: 'order.bill_address.city',             displayName: 'City',                  width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @customerCityFinalizer }
        { field: 'variant.sku',                         displayName: 'SKU',                   width: '5%',  groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'product.name',                        displayName: 'Item name',             width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'full_name',                           displayName: 'Variant',               width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'quantity',                            displayName: 'Qty',                   width: '5%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
        { field: 'max_quantity',                        displayName: 'Max Qty',               width: '5%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
        { field: 'cost',                                displayName: 'Cost',                  width: '5%', cellFilter: "customCurrency", groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
        { field: 'distribution_fee',                    displayName: 'Shipping Cost',         width: '5%', cellFilter: "customCurrency", groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
        { field: 'order.payment_method',                displayName: 'Payment method',        width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @paymentMethodFinalizer }
        { field: 'order.distributor.name',              displayName: 'Distributor',           width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @distributorFinalizer }
        { field: 'order.distributor.address.address1',  displayName: 'Distributor address',   width: '15%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @distributorAddressFinalizer }
        { field: 'order.distributor.address.city',      displayName: 'Distributor city',      width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @distributorCityFinalizer }
        { field: 'order.distributor.address.zipcode',   displayName: 'Distributor postcode',  width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @distributorPostcodeFinalizer }
        { field: 'order.special_instructions',          displayName: 'Shipping instructions', width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @shippingInstructionsFinalizer }
      ]