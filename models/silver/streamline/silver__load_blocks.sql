{{ config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    cluster_by = ['_partition_by_block_number', '_load_timestamp::DATE'],
    unique_key = 'block_id',
    full_refresh = False,
    tags = ['s3_load']
) }}

WITH blocks_json AS (

    SELECT
        block_id,
        VALUE,
        _filename,
        _load_timestamp,
        _partition_by_block_number
    FROM
        {{ ref('bronze__streamline_blocks') }}
    WHERE
        {{ partition_batch_load(150000) }}
        OR 
        (
            _partition_by_block_number IN (
                SELECT
                    DISTINCT _partition_by_block_number
                FROM
                    {{ target.database }}.tests.streamline_block_gaps
            )
            AND block_id IN (
                SELECT
                    block_id - 1
                FROM
                    {{ target.database }}.tests.streamline_block_gaps
            )
        )
        {# OR (
            _partition_by_block_number BETWEEN 86640000
            AND 86690000
        ) #}
)
SELECT
    *
FROM
    blocks_json
