{{ config(
  materialized = 'incremental',
  incremental_strategy = 'delete+insert',
  cluster_by = ['block_timestamp::DATE', '_inserted_timestamp::DATE'],
  unique_key = 'action_id',
  tags = ['curated_rpc'],
  enabled = False
) }}

WITH action_events AS (

  SELECT
    *
  FROM
    {{ ref('silver__actions_events') }}
  WHERE
    {{ incremental_load_filter('_inserted_timestamp') }}
    AND action_name = 'FunctionCall'
),
decoding AS (
  SELECT
    *,
    action_data :args AS args,
    COALESCE(TRY_PARSE_JSON(TRY_BASE64_DECODE_STRING(args)), TRY_BASE64_DECODE_STRING(args), args) AS args_decoded,
    action_data :deposit :: NUMBER AS deposit,
    action_data :gas :: NUMBER AS attached_gas,
    action_data :method_name :: STRING AS method_name
  FROM
    action_events),
    function_calls AS (
      SELECT
        action_id,
        tx_hash,
        block_id,
        block_timestamp,
        action_name,
        method_name,
        args_decoded AS args,
        deposit,
        attached_gas,
        _inserted_timestamp
      FROM
        decoding
    )
  SELECT
    *
  FROM
    function_calls
