<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Translation\TranslateTextRequest;
use App\Http\Resources\Api\V1\PhrasebookResource;
use App\Http\Resources\Api\V1\TranslationResultResource;
use App\Models\Trip;
use App\Services\Translation\TranslationService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

final class TranslationController extends Controller
{
    public function __construct(
        private readonly TranslationService $translationService,
        private readonly ApiResponse $response,
    ) {}

    /**
     * List supported offline phrasebook languages.
     */
    public function languages(): JsonResponse
    {
        return $this->response->success($this->translationService->listLanguages());
    }

    /**
     * Get curated phrasebook for a language code or country name.
     */
    public function phrasebook(Request $request, string $language): JsonResponse
    {
        $category = $request->query('category');
        $q = $request->query('q');

        $bundle = $this->translationService->getPhrasebook(
            $language,
            is_string($category) ? $category : null,
            is_string($q) ? $q : null,
        );

        return $this->response->success(new PhrasebookResource($bundle));
    }

    /**
     * Get curated phrasebook for a trip's destination country (with optional ?language= override).
     */
    public function tripPhrasebook(Request $request, Trip $trip): JsonResponse
    {
        Gate::authorize('view', $trip);

        $language = $request->query('language');
        $category = $request->query('category');
        $q = $request->query('q');

        $bundle = $this->translationService->getForTrip(
            $trip,
            is_string($language) ? $language : null,
            is_string($category) ? $category : null,
            is_string($q) ? $q : null,
        );

        return $this->response->success(new PhrasebookResource($bundle));
    }

    /**
     * Translate text using curated phrasebook match or cloud translation (requires consent_cloud=true).
     */
    public function translate(TranslateTextRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $consentCloud = (bool) $validated['consent_cloud'];

        $result = $this->translationService->translate(
            text: (string) $validated['text'],
            sourceLanguage: (string) ($validated['source_language'] ?? 'en'),
            targetLanguage: (string) $validated['target_language'],
            consentCloud: $consentCloud,
        );

        if ($result === null) {
            if (! $consentCloud) {
                return $this->response->error(
                    code: 'cloud_consent_required',
                    message: 'Phrase not found in offline phrasebook. Enable cloud translation consent to translate custom text.',
                    status: 422,
                );
            }

            return $this->response->error(
                code: 'translation_unavailable',
                message: 'Cloud translation provider is currently unavailable. Use the offline phrasebook instead.',
                status: 503,
            );
        }

        return $this->response->success(new TranslationResultResource($result));
    }
}
