<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Media\Models\MediaAttachment;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<MediaAttachment>
 */
final class MediaAttachmentFactory extends Factory
{
    protected $model = MediaAttachment::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'trip_id' => Trip::factory(),
            'attachable_type' => fake()->randomElement(['checklist_item', 'trip_document', 'stay', null]),
            'attachable_id' => fake()->uuid(),
            'uploaded_by_id' => User::factory(),
            'original_filename' => fake()->word().'.jpg',
            'file_path' => 'trips/sample/'.fake()->uuid().'.jpg',
            'mime_type' => 'image/jpeg',
            'file_size_bytes' => fake()->numberBetween(50000, 2000000),
            'title' => fake()->words(3, true),
            'notes' => fake()->optional()->sentence(),
        ];
    }
}
