<?php

declare(strict_types=1);

namespace App\Application\Checklists\Services;

use App\Domain\Checklists\Models\Checklist;

final class DeleteChecklistService
{
    /**
     * Delete a checklist.
     */
    public function handle(Checklist $checklist): void
    {
        $checklist->delete();
    }
}
