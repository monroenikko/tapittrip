<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\DTOs\Expenses\CreateExpenseData;
use App\DTOs\Expenses\UpdateExpenseData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Expenses\CreateExpenseRequest;
use App\Http\Requests\Api\V1\Expenses\UpdateExpenseRequest;
use App\Http\Requests\Api\V1\Expenses\UploadReceiptRequest;
use App\Http\Resources\Api\V1\ExpenseResource;
use App\Http\Resources\Api\V1\TripExpenseSummaryResource;
use App\Models\Expense;
use App\Models\Trip;
use App\Services\Expenses\ExpenseService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Gate;

final class TripExpenseController extends Controller
{
    public function __construct(
        private readonly ExpenseService $expenseService,
    ) {}

    /**
     * List expenses for a trip with optional category/date filtering.
     */
    public function index(Request $request, Trip $trip): AnonymousResourceCollection
    {
        Gate::authorize('view', $trip);

        $category = $request->query('category');
        $expenseDate = $request->query('expense_date');

        $expenses = $this->expenseService->getTripExpenses(
            $trip,
            is_string($category) && $category !== '' ? $category : null,
            is_string($expenseDate) && $expenseDate !== '' ? $expenseDate : null,
        );

        return ExpenseResource::collection($expenses);
    }

    /**
     * Log a new expense for a trip.
     */
    public function store(
        CreateExpenseRequest $request,
        Trip $trip,
    ): JsonResponse {
        Gate::authorize('update', $trip);

        $data = CreateExpenseData::fromArray(
            $request->validated(),
            defaultPayerId: (string) $request->user()->id,
        );

        $expense = $this->expenseService->createExpense($trip, $data);

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
    ): JsonResponse {
        Gate::authorize('update', $expense->trip);

        $data = UpdateExpenseData::fromArray($request->validated());
        $updated = $this->expenseService->updateExpense($expense, $data);

        return (new ExpenseResource($updated))
            ->response();
    }

    /**
     * Soft delete an expense.
     */
    public function destroy(
        Request $request,
        Expense $expense,
    ): Response {
        Gate::authorize('update', $expense->trip);

        $this->expenseService->deleteExpense($expense);

        return response()->noContent();
    }

    /**
     * Aggregated spending summary, category percentages, and budget utilization.
     */
    public function summary(
        Request $request,
        Trip $trip,
    ): JsonResponse {
        Gate::authorize('view', $trip);

        $result = $this->expenseService->getExpensesSummary($trip, $request->user());

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

        $updated = $this->expenseService->uploadReceipt($expense, $file);

        return (new ExpenseResource($updated))
            ->response();
    }
}
