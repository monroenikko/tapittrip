"""Validate OpenAPI and the live health response without application credentials."""
import json
import urllib.request

import yaml
from jsonschema import Draft202012Validator
from openapi_spec_validator import validate_spec

with open('/contract/openapi.yaml', encoding='utf-8') as contract_file:
    spec = yaml.safe_load(contract_file)

validate_spec(spec)
operation = spec['paths']['/health']['get']
assert operation['security'] == [], 'Health must remain unauthenticated'
response_schema = operation['responses']['200']['content']['application/json']['schema']
validator = Draft202012Validator({**response_schema, 'components': spec['components']})
with urllib.request.urlopen('http://laravel.test/api/v1/health', timeout=10) as response:
    assert response.status == 200
    assert response.headers.get_content_type() == 'application/json'
    validator.validate(json.load(response))

assert not validator.is_valid({'data': {'status': 'unexpected'}})
assert not validator.is_valid({'data': {'status': 'ok', 'secret': 'must-not-appear'}})
print('OpenAPI semantic validation and live health response passed.')
