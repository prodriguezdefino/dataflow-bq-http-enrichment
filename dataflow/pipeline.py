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
from enrichments.http import EnrichmentData, HttpEnrichmentHandler, http_enrichment_join_fn


class Options(PipelineOptions):
    """Custom pipeline options for BigQuery and HTTP endpoint configuration."""

    @classmethod
    def _add_argparse_args(cls, parser):
        parser.add_argument('--input_table', help='BigQuery table to read from')
        parser.add_argument('--output_table', help='BigQuery table to write to')
        parser.add_argument('--http_endpoint', help='HTTP endpoint to call')


def run():
    """Runs the Dataflow pipeline."""
    # Command line arguments
    pipeline_options = Options()

    # Create the pipeline
    with beam.Pipeline(options=pipeline_options) as p:
        # Read from BigQuery
        rows = p | 'ReadFromBigQuery' >> beam.io.ReadFromBigQuery(
            table=pipeline_options.input_table,
            method='DIRECT_READ'
        ) | 'ConvertToBeamRow' >> beam.Map(lambda x: beam.Row(**x))

        # Enrich with HTTP call
        enriched_rows = rows | Enrichment(
            HttpEnrichmentHandler(pipeline_options.http_endpoint),
            join_fn=http_enrichment_join_fn
        )

        # Write to BigQuery
        (enriched_rows
            | 'ConvertToDict' >> beam.Map(lambda x: x._asdict())
            | 'WriteToBigQuery' >> beam.io.WriteToBigQuery(
                pipeline_options.output_table,
                create_disposition=beam.io.BigQueryDisposition.CREATE_NEVER,
                write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND))


if __name__ == '__main__':
    run()