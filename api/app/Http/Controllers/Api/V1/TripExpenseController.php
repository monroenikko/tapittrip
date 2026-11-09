<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Application\Expenses\Data\CreateExpenseData;
use App\Application\Expenses\Data\UpdateExpenseData;
use App\Application\Expenses\Services\CreateExpenseService;
use App\Application\Expenses\Services\DeleteExpenseService;
use App\Application\Expenses\Services\GetTripExpensesSummaryService;
use App\Application\Expenses\Services\UpdateExpenseService;
use App\Domain\Expenses\Models\Expense;
use App\Domain\Trips\Models\Trip;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Expenses\CreateExpenseRequest;
use App\Http\Requests\Api\V1\Expenses\UpdateExpenseRequest;
use App\Http\Requests\Api\V1\Expenses\UploadReceiptRequest;
use App\Http\Resources\Api\V1\ExpenseResource;
use App\Http\Resources\Api\V1\TripExpenseSummaryResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;

final class TripExpenseController extends Controller
{
    /**
     * List expenses for a trip with optional category/date filtering.
     */
    public function index(Request $request, Trip $trip): AnonymousResourceCollection
    {
        Gate::authorize('view', $trip);

        $query = $trip->expenses()->with(['payer', 'itineraryItem', 'stay']);

        if ($request->has('category') && $request->filled('category')) {
            $query->where('category', $request->query('category'));
        }

        if ($request->has('expense_date') && $request->filled('expense_date')) {
            $query->whereDate('expense_date', $request->query('expense_date'));
        }

        $expenses = $query->get();

        return ExpenseResource::collection($expenses);
    }

    /**
     * Log a new expense for a trip.
     */
    public function store(
        CreateExpenseRequest $request,
        Trip $trip,
        CreateExpenseService $service,
    ): JsonResponse {
        Gate::authorize('update', $trip);

        $data = CreateExpenseData::fromArray(
            $request->validated(),
            defaultPayerId: (string) $request->user()->id,
        );

        $expense = $service->execute($trip, $data);

        return (new ExpenseResource($expense))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * Display a single expense with relationships.
     */
    public function show(Request $request, Expense $expense): JsonResponse
    {
        Gate::authorize('view', $expense->trip);

        return (new ExpenseResource($expense->load(['payer', 'itineraryItem', 'stay'])))
            ->response();
    }

    /**
     * In-place edit of an existing expense.
     */
    public function update(
        UpdateExpenseRequest $request,
        Expense $expense,
        UpdateExpenseService $service,
    ): JsonResponse {
        Gate::authorize('update', $expense->trip);

        $data = UpdateExpenseData::fromArray($request->validated());
        $updated = $service->execute($expense, $data);

        return (new ExpenseResource($updated))
            ->response();
    }

    /**
     * Soft delete an expense.
     */
    public function destroy(
        Request $request,
        Expense $expense,
        DeleteExpenseService $service,
    ): Response {
        Gate::authorize('update', $expense->trip);

        $service->execute($expense);

        return response()->noContent();
    }

    /**
     * Aggregated spending summary, category percentages, and budget utilization.
     */
    public function summary(
        Request $request,
        Trip $trip,
        GetTripExpensesSummaryService $service,
    ): JsonResponse {
        Gate::authorize('view', $trip);

        $result = $service->execute($trip, $request->user());

        return (new TripExpenseSummaryResource($result))
            ->response();
    }

    /**
     * Upload and attach a receipt photo to an expense.
     */
    public function uploadReceipt(
        UploadReceiptRequest $request,
        Expense $expense,
    ): JsonResponse {
        Gate::authorize('update', $expense->trip);

        /** @var UploadedFile $file */
        $file = $request->file('file');
        $path = $file->store("receipts/{$expense->trip_id}", 'public');
        $url = Storage::disk('public')->url($path);

        $expense->update(['receipt_url' => $url]);

        return (new ExpenseResource($expense->fresh(['payer', 'itineraryItem', 'stay', 'splits.user'])))
            ->response();
    }
}
