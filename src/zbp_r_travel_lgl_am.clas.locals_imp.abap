CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    CONSTANTS:
      BEGIN OF travel_status,
        open     TYPE c LENGTH 1 VALUE 'O', "Open
        accepted TYPE c LENGTH 1 VALUE 'A', "Accepted
        rejected TYPE c LENGTH 1 VALUE 'X', "Rejected
      END OF travel_status.

    METHODS get_instance_features FOR INSTANCE FEATURES
      keys REQUEST requested_features FOR Travel RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS acceptTravel FOR MODIFY
       keys FOR ACTION Travel~acceptTravel RESULT result.

    METHODS deductDiscount FOR MODIFY
       keys FOR ACTION Travel~deductDiscount RESULT result.

    METHODS reCaclTotalPrice FOR MODIFY
       keys FOR ACTION Travel~reCaclTotalPrice.

    METHODS rejectTravel FOR MODIFY
       keys FOR ACTION Travel~rejectTravel RESULT result.

    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
       keys FOR Travel~calculateTotalPrice.

    METHODS setStatusToOpen FOR DETERMINE ON MODIFY
       keys FOR Travel~setStatusToOpen.

    METHODS setTravelNumber FOR DETERMINE ON SAVE
       keys FOR Travel~setTravelNumber.

    METHODS validateAgency FOR VALIDATE ON SAVE
       keys FOR Travel~validateAgency.

    METHODS validateCustomer FOR VALIDATE ON SAVE
       keys FOR Travel~validateCustomer.

    METHODS validateDateRange FOR VALIDATE ON SAVE
       keys FOR Travel~validateDateRange.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_features.

    READ ENTITIES OF z_r_travel_lgl_am IN LOCAL MODE
         ENTITY Travel
         FIELDS ( OverallStatus )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels)
         FAILED failed.

    result = VALUE #( FOR travel IN travels (
                                 %tky = travel-%tky
                                 %field-BookingFee = COND #( WHEN travel-OverallStatus = travel_status-accepted
                                                             THEN if_abap_behv=>fc-f-read_only
                                                             ELSE if_abap_behv=>fc-f-unrestricted )
                                 %action-acceptTravel = COND #( WHEN travel-OverallStatus = travel_status-accepted
                                                                THEN if_abap_behv=>fc-o-disabled
                                                                ELSE if_abap_behv=>fc-o-enabled )
                                 %action-rejectTravel = COND #( WHEN travel-OverallStatus = travel_status-rejected
                                                                THEN if_abap_behv=>fc-o-disabled
                                                                ELSE if_abap_behv=>fc-o-enabled )
                                 %action-deductDiscount = COND #( WHEN travel-OverallStatus = travel_status-accepted
                                                                  THEN if_abap_behv=>fc-o-disabled
                                                                  ELSE if_abap_behv=>fc-o-enabled )
                        ) ).

  ENDMETHOD.

  METHOD get_instance_authorizations.

    DATA: update_requested TYPE abap_bool,
          update_granted   TYPE abap_bool,
          delete_requested TYPE abap_bool,
          delete_granted   TYPE abap_bool.

    READ ENTITIES OF z_r_travel_lgl_am IN LOCAL MODE
    ENTITY Travel
    FIELDS ( AgencyID )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels)
    FAILED failed.

    update_requested = COND #( WHEN requested_authorizations-%update = if_abap_behv=>mk-on
                                OR requested_authorizations-%action-Edit = if_abap_behv=>mk-on
                                THEN abap_true
                                ELSE abap_false ).


    delete_requested = COND #( WHEN requested_authorizations-%delete = if_abap_behv=>mk-on
                               THEN abap_true
                               ELSE abap_false ).

*    CHECK update_requested EQ abap_true.

    DATA(lv_technical_name) = cl_abap_context_info=>get_user_technical_name(  ).

    LOOP AT travels INTO DATA(travel) "70021
      WHERE AgencyID     IS NOT INITIAL.

      IF update_requested EQ abap_true.
        IF lv_technical_name EQ 'CB9980000903' AND travel-AgencyID NE '70021'.
          update_granted = abap_true.
        ELSE.
          update_granted = abap_false.

        ENDIF.
      ENDIF.

      IF delete_requested EQ abap_true.
        IF lv_technical_name EQ 'CB9980000903' AND travel-AgencyID NE '70021'.
          delete_granted = abap_true.
        ELSE.
          delete_granted = abap_false.

        ENDIF.
      ENDIF.

      APPEND VALUE #( LET upd_auth = COND #( WHEN update_granted EQ abap_true
                                             THEN if_abap_behv=>auth-allowed
                                             ELSE if_abap_behv=>auth-unauthorized  )
                          del_auth = COND #( WHEN delete_granted EQ abap_true
                                             THEN if_abap_behv=>auth-allowed
                                             ELSE if_abap_behv=>auth-unauthorized )
                      IN
                      %tky = travel-%tky
                      %update = upd_auth
                      %action-Edit = upd_auth
                      %delete = del_auth ) TO result.

    ENDLOOP.

  ENDMETHOD.

  METHOD get_global_authorizations.

    DATA(lv_technical_name) = cl_abap_context_info=>get_user_technical_name(  ).

*    lv_technical_name = 'DIFERENT USER'.

    IF requested_authorizations-%create EQ if_abap_behv=>mk-on.
      IF lv_technical_name EQ 'CB9980000903'.
        result-%create = if_abap_behv=>auth-allowed.
      ELSE.
        result-%create = if_abap_behv=>auth-unauthorized.
      ENDIF.
    ENDIF.

    IF requested_authorizations-%update EQ if_abap_behv=>mk-on OR
       requested_authorizations-%action-Edit EQ if_abap_behv=>mk-on.

      IF lv_technical_name EQ 'CB9980000903'.
        result-%update = if_abap_behv=>auth-allowed.
        result-%action-Edit = if_abap_behv=>auth-allowed.
      ELSE.
        result-%update = if_abap_behv=>auth-unauthorized.
        result-%action-Edit = if_abap_behv=>auth-unauthorized.
      ENDIF.

    ENDIF.

    IF requested_authorizations-%delete EQ if_abap_behv=>mk-on.

      IF lv_technical_name EQ 'CB9980000903'.
        result-%delete = if_abap_behv=>auth-allowed.
      ELSE.
        result-%delete = if_abap_behv=>auth-unauthorized.
      ENDIF.

    ENDIF.

  ENDMETHOD.

  METHOD acceptTravel.

* EML - Entity Manipulate Language
    MODIFY ENTITIES OF z_r_travel_lgl_am IN LOCAL MODE
        ENTITY Travel
        UPDATE
        FIELDS ( OverallStatus )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky
                                        OverallStatus = travel_status-accepted ) ).

    READ ENTITIES OF z_r_travel_lgl_am IN LOCAL MODE
        ENTITY Travel
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(travels).

    result = VALUE #( FOR travel IN travels ( %tky = travel-%tky
                                              %param = travel ) ).

  ENDMETHOD.

  METHOD deductDiscount.

    DATA travels_for_update TYPE TABLE FOR UPDATE z_r_travel_lgl_am.

    READ ENTITIES OF z_r_travel_lgl_am IN LOCAL MODE
          ENTITY Travel
          FIELDS ( BookingFee )
          WITH CORRESPONDING #( keys )
          RESULT DATA(travels).

    DATA percentage TYPE decfloat16.

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
*      KEY id %tky -->  indica que el "key" o campo clave es el "id" cuyo valor viene en "%tky" que tiene que ser igual a <travel>-%tky
      DATA(discount_percentage) = keys[ KEY id %tky = <travel>-%tky ]-%param-discount_percent.
      percentage = discount_percentage / 100.
      DATA(reduced_fee) = <travel>-BookingFee * ( 1 - percentage ).

      APPEND VALUE #( %tky = <travel>-%tky
                      BookingFee = reduced_fee ) TO travels_for_update.

    ENDLOOP.

    MODIFY ENTITIES OF z_r_travel_lgl_am IN LOCAL MODE
    ENTITY Travel
    UPDATE
    FIELDS ( BookingFee )
    WITH travels_for_update.

    READ ENTITIES OF z_r_travel_lgl_am IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels_with_discount).

    result = VALUE #( FOR travel IN travels_with_discount ( %tky = travel-%tky
                                                            %param = travel ) ).

  ENDMETHOD.

  METHOD reCaclTotalPrice.
  ENDMETHOD.

  METHOD rejectTravel.

* eml - Entity Manipulate Language
    MODIFY ENTITIES OF z_r_travel_lgl_am IN LOCAL MODE
        ENTITY Travel
        UPDATE
        FIELDS ( OverallStatus )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky
                                        OverallStatus = travel_status-rejected ) ).

    READ ENTITIES OF z_r_travel_lgl_am IN LOCAL MODE
        ENTITY Travel
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(travels).

    result = VALUE #( FOR travel IN travels ( %tky = travel-%tky
                                              %param = travel ) ).
  ENDMETHOD.

  METHOD calculateTotalPrice.
  ENDMETHOD.

  METHOD setStatusToOpen.
  ENDMETHOD.

  METHOD setTravelNumber.
  ENDMETHOD.

  METHOD validateAgency.
  ENDMETHOD.

  METHOD validateCustomer.
  ENDMETHOD.

  METHOD validateDateRange.
  ENDMETHOD.

ENDCLASS.
