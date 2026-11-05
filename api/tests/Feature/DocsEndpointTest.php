<?php

declare(strict_types=1);

namespace Tests\Feature;

use Tests\TestCase;

final class DocsEndpointTest extends TestCase
{
    public function test_docs_page_is_accessible(): void
    {
        $response = $this->get('/docs');

        $response
            ->assertOk()
            ->assertSee('SwaggerUIBundle', false);
    }

    public function test_openapi_yaml_contract_is_served(): void
    {
        $response = $this->get('/docs/openapi.yaml');

        $response
            ->assertOk()
            ->assertHeader('Content-Type', 'text/yaml; charset=utf-8')
            ->assertSee('openapi: 3.1.0', false)
            ->assertSee('TapItTrip API', false);
    }
}
