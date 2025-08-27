# Copyright (C) 2025 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions
from apache_beam.transforms.enrichment import Enrichment
from apache_beam.transforms.enrichment import EnrichmentHandler
import requests


class HttpEnrichmentHandler(EnrichmentHandler):
    def __init__(self, http_endpoint):
        self.http_endpoint = http_endpoint

    def __call__(self, request, *args, **kwargs):
        try:
            with requests.post(self.http_endpoint, json=request._asdict(), stream=True) as response:
                response.raise_for_status()
                full_response = b"".join(response.iter_content(chunk_size=8192))
                return request, full_response.decode('utf-8')
        except Exception as e:
            return request, str(e)


class MyPipelineOptions(PipelineOptions):
    @classmethod
    def _add_argparse_args(cls, parser):
        parser.add_argument('--input_table', help='BigQuery table to read from')
        parser.add_argument('--output_table', help='BigQuery table to write to')
        parser.add_argument('--http_endpoint', help='HTTP endpoint to call')


def run():
    # Command line arguments
    pipeline_options = MyPipelineOptions()

    # Create the pipeline
    with beam.Pipeline(options=pipeline_options) as p:
        # Read from BigQuery
        rows = p | 'ReadFromBigQuery' >> beam.io.ReadFromBigQuery(
            table=pipeline_options.input_table,
        )

        # Enrich with HTTP call
        enriched_rows = rows | Enrichment(
            HttpEnrichmentHandler(pipeline_options.http_endpoint))

        # Write to BigQuery
        enriched_rows | 'WriteToBigQuery' >> beam.io.WriteToBigQuery(
            pipeline_options.output_table,
            schema='id:INTEGER,data:STRING,http_response:STRING',
            create_disposition=beam.io.BigQueryDisposition.CREATE_NEVER,
            write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND,
            row_mapper=lambda x: {
                'id': x.request.id,
                'data': x.request.data,
                'http_response': x.response
            }
        )


if __name__ == '__main__':
    run()