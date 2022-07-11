CLASS zcl_abapgit_json_handler DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! Serializes data to xstring. Type of data is specified in the
    "! implementing class.
    "!
    "! @parameter iv_data | data to be serialized
    "! @parameter rv_result | serialized data
    METHODS serialize
      IMPORTING iv_data          TYPE data
      RETURNING VALUE(rv_result) TYPE xstring
      RAISING   cx_static_check.

    "! Deserializes xstring into data. The type of data is specified in
    "! the implementing class
    "!
    "! @parameter iv_content | xstring to be deserialized
    "! @parameter ev_data | data of the xstring
    METHODS deserialize
      IMPORTING iv_content TYPE xstring
      EXPORTING ev_data    TYPE data
      RAISING   cx_static_check.
  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS zcl_abapgit_json_handler IMPLEMENTATION.


  METHOD deserialize.
    DATA lv_json    TYPE string.
    DATA lo_ajson   TYPE REF TO zcl_abapgit_ajson.
    DATA lo_mapping TYPE REF TO zif_abapgit_ajson_mapping.

    CLEAR ev_data.

    lv_json = zcl_abapgit_convert=>xstring_to_string_utf8( iv_content ).
    lo_mapping = zcl_abapgit_ajson_mapping=>create_camel_case( ).

    lo_ajson = zcl_abapgit_ajson=>parse( iv_json           = lv_json
                                         ii_custom_mapping = lo_mapping ).

    lo_ajson->zif_abapgit_ajson~to_abap( IMPORTING ev_container = ev_data ).

  ENDMETHOD.


  METHOD serialize.
    DATA: lt_st_source      TYPE abap_trans_srcbind_tab,
          lo_mapping        TYPE REF TO zif_abapgit_ajson_mapping,
          lv_json           TYPE string,
          lo_ajson          TYPE REF TO zcl_abapgit_ajson,
          lo_ajson_filtered TYPE REF TO zif_abapgit_ajson,
          lo_filter         TYPE REF TO lcl_aff_filter,
          lv_enum_json      TYPE string.

    FIELD-SYMBOLS: <lg_source> LIKE LINE OF lt_st_source.

    APPEND INITIAL LINE TO lt_st_source ASSIGNING <lg_source>.
    GET REFERENCE OF iv_data INTO <lg_source>-value.

    lo_mapping = zcl_abapgit_ajson_mapping=>create_camel_case( iv_first_json_upper = abap_false ).

    lo_ajson = zcl_abapgit_ajson=>create_empty( lo_mapping ).

    lo_ajson->keep_item_order( ).
    lo_ajson->set(
      iv_path = '/'
      iv_val  = iv_data ).

    " [!] INTF specific
    lv_enum_json = lo_ajson->get_string( iv_path = '/category' ).
    IF lv_enum_json = `00`.
      lo_ajson->set_string(
       iv_path = '/category'
       iv_val  = `` ).
    ELSEIF lv_enum_json = `01`.
      lo_ajson->set_string(
       iv_path = '/category'
       iv_val  = `classicBadi` ).
    ENDIF.

    CREATE OBJECT lo_filter.
    lo_ajson_filtered = zcl_abapgit_ajson=>create_from(
                          ii_source_json = lo_ajson
                          ii_filter      = lo_filter ).

    lo_ajson_filtered->keep_item_order( ).

    lv_json = lo_ajson_filtered->stringify( 2 ).

    rv_result = zcl_abapgit_convert=>string_to_xstring_utf8( lv_json ).

  ENDMETHOD.

ENDCLASS.
