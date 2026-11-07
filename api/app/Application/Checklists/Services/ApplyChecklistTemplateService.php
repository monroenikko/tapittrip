<?php

declare(strict_types=1);

namespace App\Application\Checklists\Services;

use App\Domain\Checklists\Models\Checklist;
use App\Domain\Checklists\Models\ChecklistItem;
use App\Domain\Trips\Models\Trip;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

final class ApplyChecklistTemplateService
{
    /**
     * @var array<string, array{title: string, type: string, description: string, items: array<int, array{title: string, category: string, quantity: int}>}>
     */
    private const TEMPLATES = [
        'international_essentials' => [
            'title' => 'International Essentials',
            'type' => 'packing',
            'description' => 'Essential travel documents, international currency, and core travel gear.',
            'items' => [
                ['title' => 'Passport & Visa Copies', 'category' => 'documents', 'quantity' => 1],
                ['title' => 'Boarding Passes & Tickets', 'category' => 'documents', 'quantity' => 1],
                ['title' => 'Travel Insurance & Health Cards', 'category' => 'documents', 'quantity' => 1],
                ['title' => 'Local Currency & Credit Cards', 'category' => 'documents', 'quantity' => 1],
                ['title' => 'Universal Power Adapter', 'category' => 'electronics', 'quantity' => 1],
                ['title' => 'Phone Charger & Cables', 'category' => 'electronics', 'quantity' => 1],
                ['title' => 'Portable Power Bank', 'category' => 'electronics', 'quantity' => 1],
                ['title' => 'Personal Medications & First Aid', 'category' => 'health', 'quantity' => 1],
                ['title' => 'Toothbrush & Toothpaste', 'category' => 'toiletries', 'quantity' => 1],
                ['title' => 'TSA-compliant Liquids Bag', 'category' => 'toiletries', 'quantity' => 1],
            ],
        ],
        'electronics_gear' => [
            'title' => 'Electronics & Tech',
            'type' => 'packing',
            'description' => 'Chargers, adapters, devices, and entertainment.',
            'items' => [
                ['title' => 'Smartphone & Charger', 'category' => 'electronics', 'quantity' => 1],
                ['title' => 'Noise-Cancelling Headphones', 'category' => 'electronics', 'quantity' => 1],
                ['title' => 'Power Bank / Battery Pack', 'category' => 'electronics', 'quantity' => 1],
                ['title' => 'Universal Plug Adapter', 'category' => 'electronics', 'quantity' => 1],
                ['title' => 'Laptop / Tablet & Charger', 'category' => 'electronics', 'quantity' => 1],
                ['title' => 'Extra USB Cables', 'category' => 'electronics', 'quantity' => 2],
                ['title' => 'Camera & Memory Cards', 'category' => 'electronics', 'quantity' => 1],
            ],
        ],
        'clothing_apparel' => [
            'title' => 'Clothing & Apparel',
            'type' => 'packing',
            'description' => 'Apparel, shoes, and layers for the journey.',
            'items' => [
                ['title' => 'T-Shirts & Tops', 'category' => 'clothing', 'quantity' => 5],
                ['title' => 'Pants & Shorts', 'category' => 'clothing', 'quantity' => 3],
                ['title' => 'Underwear & Socks', 'category' => 'clothing', 'quantity' => 5],
                ['title' => 'Sleepwear & Pajamas', 'category' => 'clothing', 'quantity' => 2],
                ['title' => 'Lightweight Jacket or Fleece', 'category' => 'clothing', 'quantity' => 1],
                ['title' => 'Comfortable Walking Shoes', 'category' => 'clothing', 'quantity' => 1],
                ['title' => 'Rain Jacket or Umbrella', 'category' => 'clothing', 'quantity' => 1],
            ],
        ],
        'toiletries_health' => [
            'title' => 'Toiletries & Health',
            'type' => 'packing',
            'description' => 'Hygiene essentials, skin protection, and health items.',
            'items' => [
                ['title' => 'Toothbrush & Floss', 'category' => 'toiletries', 'quantity' => 1],
                ['title' => 'Travel Size Shampoo & Body Wash', 'category' => 'toiletries', 'quantity' => 1],
                ['title' => 'Deodorant', 'category' => 'toiletries', 'quantity' => 1],
                ['title' => 'Sunscreen & Lip Balm', 'category' => 'toiletries', 'quantity' => 1],
                ['title' => 'Pain Relievers & Prescription Meds', 'category' => 'health', 'quantity' => 1],
                ['title' => 'Bandages & Antiseptic Wipes', 'category' => 'health', 'quantity' => 1],
                ['title' => 'Motion Sickness / Allergy Meds', 'category' => 'health', 'quantity' => 1],
            ],
        ],
        'all_essentials' => [
            'title' => 'Trip Packing Essentials',
            'type' => 'packing',
            'description' => 'Comprehensive checklist covering documents, electronics, clothing, toiletries, and health.',
            'items' => [], // Populated dynamically by merging above
        ],
        'departure_day' => [
            'title' => 'Departure Day Checklist',
            'type' => 'departure',
            'description' => 'Final day checklist before leaving home: keys, appliances, passports, and luggage checks.',
            'items' => [
                ['title' => 'Check flight status & online check-in', 'category' => 'documents', 'quantity' => 1],
                ['title' => 'Physical passport, ID & visa in hand', 'category' => 'documents', 'quantity' => 1],
                ['title' => 'Luggage weighed & luggage tags attached', 'category' => 'gear', 'quantity' => 1],
                ['title' => 'Water bottle emptied before airport security', 'category' => 'gear', 'quantity' => 1],
                ['title' => 'House keys, wallet & phone in personal bag', 'category' => 'documents', 'quantity' => 1],
                ['title' => 'Turn off home appliances & lock doors/windows', 'category' => 'other', 'quantity' => 1],
            ],
        ],
        'return_trip' => [
            'title' => 'Return Trip Checklist',
            'type' => 'return',
            'description' => 'Hotel room departure checks, souvenir packing, tax-free receipts, and airport return transit.',
            'items' => [
                ['title' => 'Check hotel room safe & wardrobe', 'category' => 'other', 'quantity' => 1],
                ['title' => 'Return room keys & settle hotel bill', 'category' => 'other', 'quantity' => 1],
                ['title' => 'Souvenirs & tax-free receipts organized', 'category' => 'documents', 'quantity' => 1],
                ['title' => 'Repack liquids in checked luggage', 'category' => 'gear', 'quantity' => 1],
                ['title' => 'Passport, return tickets & boarding passes ready', 'category' => 'documents', 'quantity' => 1],
                ['title' => 'Confirm airport return transit & departure terminal', 'category' => 'other', 'quantity' => 1],
            ],
        ],
    ];

    /**
     * Apply a starter template to a trip.
     */
    public function handle(Trip $trip, string $templateKey): Checklist
    {
        if (! array_key_exists($templateKey, self::TEMPLATES)) {
            throw new InvalidArgumentException("Unknown checklist template [{$templateKey}].");
        }

        $template = self::TEMPLATES[$templateKey];

        /** @var array<int, array{title: string, category: string, quantity: int}> $items */
        $items = $template['items'];

        if ($templateKey === 'all_essentials') {
            $items = array_merge(
                self::TEMPLATES['international_essentials']['items'],
                self::TEMPLATES['electronics_gear']['items'],
                self::TEMPLATES['clothing_apparel']['items'],
                self::TEMPLATES['toiletries_health']['items'],
            );
        }

        return DB::transaction(function () use ($trip, $template, $items): Checklist {
            /** @var Checklist $checklist */
            $checklist = Checklist::query()->create([
                'trip_id' => $trip->id,
                'title' => $template['title'],
                'type' => $template['type'],
                'description' => $template['description'],
                'sort_order' => $trip->checklists()->count(),
            ]);

            $order = 0;
            foreach ($items as $item) {
                ChecklistItem::query()->create([
                    'checklist_id' => $checklist->id,
                    'trip_id' => $trip->id,
                    'title' => $item['title'],
                    'category' => $item['category'],
                    'is_packed' => false,
                    'quantity' => $item['quantity'],
                    'notes' => null,
                    'photo_url' => null,
                    'sort_order' => $order++,
                    'packed_at' => null,
                    'version' => 1,
                ]);
            }

            return $checklist->load('items');
        });
    }

    /**
     * Get available template keys and metadata.
     *
     * @return array<int, array{key: string, title: string, description: string, item_count: int}>
     */
    public static function availableTemplates(): array
    {
        $result = [];
        foreach (self::TEMPLATES as $key => $tpl) {
            $count = count($tpl['items']);
            if ($key === 'all_essentials') {
                $count = count(self::TEMPLATES['international_essentials']['items'])
                    + count(self::TEMPLATES['electronics_gear']['items'])
                    + count(self::TEMPLATES['clothing_apparel']['items'])
                    + count(self::TEMPLATES['toiletries_health']['items']);
            }

            $result[] = [
                'key' => $key,
                'title' => $tpl['title'],
                'description' => $tpl['description'],
                'item_count' => $count,
            ];
        }

        return $result;
    }
}
