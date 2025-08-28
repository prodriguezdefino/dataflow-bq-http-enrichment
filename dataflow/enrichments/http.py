from typing import Any, Dict, NamedTuple, Tuple
import apache_beam as beam
import requests
import logging

EnrichmentData = NamedTuple('EnrichmentData', [('http_response', str)])

def http_enrichment_join_fn(left: dict, right: dict) -> beam.Row:
    """Custom join function to merge original data with HTTP response."""
    logging.info(f"left {left}, right {right}")
    return beam.Row(
        id=left['id'],
        data=left['data'],
        http_response=right['http_response']
    )

class HttpEnrichmentHandler(beam.transforms.enrichment.EnrichmentSourceHandler):
    """A custom enrichment handler for making HTTP POST requests."""

    def __init__(self, http_endpoint: str):
        self.http_endpoint = http_endpoint
        self.session: requests.Session = None

    def setup(self):
        """Initializes the requests session for reusing TCP connections."""
        logging.info("initializing http session...")
        self.session = requests.Session()

    def __call__(self, request: beam.Row, *args: Any, **kwargs: Any) -> Tuple[beam.Row, EnrichmentData]:
        """Makes an HTTP POST request and returns the response.

        Args:
            request: The input Beam Row containing data for the request.

        Returns:
            A tuple containing the original request and an EnrichmentData object with the HTTP response.
        """
        if self.session is None:
            logging.warn("http session not initialized.")
            self.setup() # Re-initialize session if it's None
        try:
            with self.session.post(self.http_endpoint, json=request._asdict(), stream=True) as response:
                response.raise_for_status()
                full_response = b"".join(response.iter_content(chunk_size=8192))
                return request, EnrichmentData(http_response=full_response.decode('utf-8'))
        except Exception as e:
            # In a production scenario, more robust error handling and logging would be implemented.
            return request, EnrichmentData(http_response=str(e))

    def teardown(self):
        """Closes the requests session."""
        if self.session:
            self.session.close()
