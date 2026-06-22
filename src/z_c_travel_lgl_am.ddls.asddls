@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Travel - Consumption'
@Metadata.ignorePropagatedAnnotations: true
define root view entity Z_C_TRAVEL_LGL_AM
  provider contract transactional_query
  as projection on Z_R_TRAVEL_LGL_AM
{
  key TravelUUID,
      TravelID,

      @ObjectModel.text.element: [ 'AgencyName' ]
      AgencyID,
      _Agency.Name       as AgencyName,

      @ObjectModel.text.element: [ 'CustomerName' ]
      CustomerID,
      _Customer.LastName as CustomerName,

      BeginDate,
      EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      TotalPrice,
      CurrencyCode,
      Description,
      OverallStatus,
      //Se eliminó el resto de campos de auditoria solo para el ejecicio, puede ir sin problema
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      LastChangedAt,
      /* Associations */
      _Agency,
      _Currency,
      _Customer,
      _OverallStatus
}
