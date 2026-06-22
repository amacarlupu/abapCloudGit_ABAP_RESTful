@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Travel - Interface'
@Metadata.ignorePropagatedAnnotations: true
//"false" para heredar atributos desde entidad anterior
define root view entity Z_I_TRAVEL_LGL_AM
  provider contract transactional_interface
  as projection on Z_R_TRAVEL_LGL_AM
{
  key TravelUUID,
      TravelID,
      AgencyID,
      CustomerID,
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
