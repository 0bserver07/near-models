{{ config(
    materialized = 'incremental',
    unique_key = '_res_id',
    incremental_strategy = 'merge',
    cluster_by = ['_inserted_timestamp::date', 'token_contract'],
    tags = ['api']
) }}

WITH nearblocks_token_api AS (

    SELECT
        *
    FROM
        {{ target.database }}.bronze_api.nearblocks_fts
    WHERE
        {{ incremental_load_filter('_inserted_timestamp') }}
        qualify ROW_NUMBER() over (
            PARTITION BY concat_ws(
                '-',
                _inserted_timestamp :: DATE,
                token_contract
            )
            ORDER BY
                _inserted_timestamp DESC
        ) = 1
),
FINAL AS (
    SELECT
        _inserted_timestamp :: DATE AS DATE,
        token_name AS token,
        token_contract,
        token_data,
        token_data :decimals :: NUMBER AS decimals,
        token_data :symbol :: STRING AS symbol,
        provider,
        _inserted_timestamp,
        _res_id
    FROM
        nearblocks_token_api
)
SELECT
    *
FROM
    FINAL
