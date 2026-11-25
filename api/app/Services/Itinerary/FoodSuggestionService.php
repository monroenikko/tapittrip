<?php

declare(strict_types=1);

namespace App\Services\Itinerary;

use App\Models\ItineraryItem;
use App\Models\Stay;
use App\Models\Trip;

final class FoodSuggestionService
{
    /**
     * Generate curated, destination- and stay-aware restaurant & food suggestions for a trip.
     *
     * @param  array<string, mixed>  $filters
     * @return array<string, mixed>
     */
    public function suggestForTrip(Trip $trip, array $filters = []): array
    {
        $mealType = isset($filters['meal_type']) && is_string($filters['meal_type']) && trim($filters['meal_type']) !== ''
            ? strtolower(trim($filters['meal_type']))
            : 'all';
        $dietary = isset($filters['dietary']) && is_string($filters['dietary']) && trim($filters['dietary']) !== ''
            ? strtolower(trim($filters['dietary']))
            : null;
        $near = isset($filters['near']) && is_string($filters['near']) && trim($filters['near']) !== ''
            ? strtolower(trim($filters['near']))
            : 'stay';

        /** @var Stay|null $stay */
        $stay = $trip->stays()->orderBy('check_in_at')->first();

        /** @var list<ItineraryItem> $itineraryItems */
        $itineraryItems = $trip->itineraryItems()->with('place')->get()->all();

        $existingNames = [];
        foreach ($itineraryItems as $item) {
            $existingNames[mb_strtolower(trim($item->title))] = true;
            if ($item->place !== null) {
                $existingNames[mb_strtolower(trim($item->place->name))] = true;
            }
        }

        $firstStopName = null;
        foreach ($itineraryItems as $item) {
            if ($item->place !== null && trim($item->place->name) !== '') {
                $firstStopName = trim($item->place->name);
                break;
            }
            if (trim($item->title) !== '') {
                $firstStopName = trim($item->title);
                break;
            }
        }

        $proximityLabel = $this->resolveProximityLabel($near, $stay, $firstStopName, $trip->title);
        $destinationLabel = trim($trip->title.($trip->destination_country ? " ({$trip->destination_country})" : ''));
        $catalog = $this->buildDestinationCatalog($trip, $proximityLabel);

        $suggestions = [];
        foreach ($catalog as $entry) {
            $nameLower = mb_strtolower($entry['name']);
            $titleLower = mb_strtolower($entry['suggested_title']);
            if (isset($existingNames[$nameLower]) || isset($existingNames[$titleLower])) {
                continue;
            }

            if ($mealType !== 'all' && $entry['meal_type'] !== $mealType) {
                continue;
            }

            if ($dietary !== null && ! in_array($dietary, $entry['dietary_tags'], true)) {
                continue;
            }

            $searchQuery = trim($entry['name'].', '.$entry['neighborhood'].', '.$trip->title);
            $mapsUrl = 'https://www.google.com/maps/search/?'.http_build_query([
                'api' => '1',
                'query' => $searchQuery,
            ], '', '&', PHP_QUERY_RFC3986);

            $suggestions[] = [
                'id' => $entry['id'],
                'name' => $entry['name'],
                'cuisine' => $entry['cuisine'],
                'meal_type' => $entry['meal_type'],
                'neighborhood' => $entry['neighborhood'],
                'proximity_label' => $entry['proximity_label'],
                'dietary_tags' => $entry['dietary_tags'],
                'price_tier' => $entry['price_tier'],
                'notes' => $entry['notes'],
                'google_maps_search_url' => $mapsUrl,
                'suggested_action' => [
                    'label' => 'Add '.$entry['suggested_title'],
                    'kind' => 'add_activity',
                    'payload' => [
                        'title' => $entry['suggested_title'],
                        'kind' => 'meal',
                        'place_name' => $entry['name'],
                        'notes' => $entry['notes'].' ('.$entry['proximity_label'].')',
                    ],
                ],
                'provider_attribution' => 'TapItTrip Curated Culinary Directory',
                'verified' => false,
            ];
        }

        return [
            'trip_id' => $trip->id,
            'destination' => $destinationLabel,
            'anchor_stay_name' => $stay?->name,
            'filters_applied' => [
                'meal_type' => $mealType,
                'dietary' => $dietary,
                'near' => $near,
            ],
            'source' => 'curated_directory',
            'verified' => false,
            'advisory_notice' => 'Restaurant suggestions are curated dining ideas and do not reflect live opening hours, menu prices, or table availability. Confirm venue details in Google Maps before visiting.',
            'suggestions' => $suggestions,
        ];
    }

    private function resolveProximityLabel(string $near, ?Stay $stay, ?string $firstStopName, string $tripTitle): string
    {
        if ($near === 'itinerary' && $firstStopName !== null) {
            return "Walking distance from {$firstStopName}";
        }

        if ($stay !== null && trim($stay->name) !== '') {
            return "5–10 min walk from {$stay->name}";
        }

        if ($firstStopName !== null) {
            return "Near {$firstStopName}";
        }

        return "Central {$tripTitle} dining district";
    }

    /**
     * @return list<array{
     *   id: string,
     *   name: string,
     *   suggested_title: string,
     *   cuisine: string,
     *   meal_type: string,
     *   neighborhood: string,
     *   proximity_label: string,
     *   dietary_tags: list<string>,
     *   price_tier: string,
     *   notes: string
     * }>
     */
    private function buildDestinationCatalog(Trip $trip, string $proximityLabel): array
    {
        $country = strtoupper((string) ($trip->destination_country ?? ''));
        $titleLower = mb_strtolower($trip->title);

        if ($country === 'JP' || str_contains($titleLower, 'tokyo') || str_contains($titleLower, 'kyoto') || str_contains($titleLower, 'osaka')) {
            return [
                [
                    'id' => 'food-jp-breakfast-1',
                    'name' => 'Asakusa Kissaten & Artisanal Toast Roastery',
                    'suggested_title' => 'Breakfast at Asakusa Kissaten Roastery',
                    'cuisine' => 'Japanese Kissaten & Specialty Coffee',
                    'meal_type' => 'breakfast',
                    'neighborhood' => 'Asakusa / Taito',
                    'proximity_label' => $proximityLabel,
                    'dietary_tags' => ['vegetarian', 'kid_friendly', 'local_specialty'],
                    'price_tier' => 'budget',
                    'notes' => 'Thick-cut shokupan toast sets, hand-drip coffee, and quiet morning booths.',
                ],
                [
                    'id' => 'food-jp-lunch-1',
                    'name' => 'Teuchi Udon & Tempura Kitchen',
                    'suggested_title' => 'Lunch at Teuchi Udon & Tempura Kitchen',
                    'cuisine' => 'Handmade Udon & Seasonal Tempura',
                    'meal_type' => 'lunch',
                    'neighborhood' => 'Shibuya / Harajuku',
                    'proximity_label' => $proximityLabel,
                    'dietary_tags' => ['vegetarian', 'kid_friendly', 'local_specialty'],
                    'price_tier' => 'moderate',
                    'notes' => 'Freshly rolled udon noodles with dashi or vegan kombu broth and English photo menu.',
                ],
                [
                    'id' => 'food-jp-dinner-1',
                    'name' => 'Shinjuku Charcoal Yakitori & Teishoku Dining',
                    'suggested_title' => 'Dinner at Shinjuku Teishoku Dining',
                    'cuisine' => 'Japanese Set Meals (Teishoku) & Grill',
                    'meal_type' => 'dinner',
                    'neighborhood' => 'Shinjuku',
                    'proximity_label' => $proximityLabel,
                    'dietary_tags' => ['kid_friendly', 'halal', 'local_specialty'],
                    'price_tier' => 'moderate',
                    'notes' => 'Balanced grilled fish, halal-friendly chicken skewers, miso soup, and family table seating.',
                ],
                [
                    'id' => 'food-jp-cafe-1',
                    'name' => 'Uji Matcha Parfait & Wagashi Tea House',
                    'suggested_title' => 'Afternoon Tea at Matcha & Wagashi House',
                    'cuisine' => 'Japanese Tea House & Desserts',
                    'meal_type' => 'cafe',
                    'neighborhood' => 'Ginza / Chuo',
                    'proximity_label' => $proximityLabel,
                    'dietary_tags' => ['vegetarian', 'kid_friendly', 'local_specialty'],
                    'price_tier' => 'budget',
                    'notes' => 'Stone-milled Uji matcha lattes, warabimochi, and stroller-friendly ground-floor entry.',
                ],
            ];
        }

        if ($country === 'PH' || str_contains($titleLower, 'manila') || str_contains($titleLower, 'cebu') || str_contains($titleLower, 'boracay')) {
            return [
                [
                    'id' => 'food-ph-breakfast-1',
                    'name' => 'Heritage Tsokolate & Pandesal Cafe',
                    'suggested_title' => 'Breakfast at Heritage Tsokolate & Pandesal Cafe',
                    'cuisine' => 'Filipino Breakfast & Artisanal Bakery',
                    'meal_type' => 'breakfast',
                    'neighborhood' => 'Makati / BGC',
                    'proximity_label' => $proximityLabel,
                    'dietary_tags' => ['vegetarian', 'kid_friendly', 'local_specialty'],
                    'price_tier' => 'budget',
                    'notes' => 'Warm pugon pandesal, tablea hot chocolate, and classic garlic rice breakfast platters.',
                ],
                [
                    'id' => 'food-ph-lunch-1',
                    'name' => 'Modern Filipino Sinigang & Seafood Bistro',
                    'suggested_title' => 'Lunch at Modern Filipino Seafood Bistro',
                    'cuisine' => 'Contemporary Filipino Comfort Food',
                    'meal_type' => 'lunch',
                    'neighborhood' => 'Poblacion / Bonifacio High Street',
                    'proximity_label' => $proximityLabel,
                    'dietary_tags' => ['kid_friendly', 'local_specialty', 'vegetarian'],
                    'price_tier' => 'moderate',
                    'notes' => 'Tamarind sinigang, grilled catch of the day, and fresh ensalada with family sharing portions.',
                ],
                [
                    'id' => 'food-ph-dinner-1',
                    'name' => 'Harborfront Grill & Halal Mindanao Kitchen',
                    'suggested_title' => 'Dinner at Harborfront Grill & Kitchen',
                    'cuisine' => 'Filipino Grill & Southern Specialties',
                    'meal_type' => 'dinner',
                    'neighborhood' => 'Bay Area / Seaside',
                    'proximity_label' => $proximityLabel,
                    'dietary_tags' => ['halal', 'kid_friendly', 'local_specialty'],
                    'price_tier' => 'moderate',
                    'notes' => 'Charcoal-grilled seafood, beef rendang, and breezy indoor/outdoor family seating.',
                ],
                [
                    'id' => 'food-ph-cafe-1',
                    'name' => 'Halo-Halo & Cordillera Arabica Roasters',
                    'suggested_title' => 'Merienda at Halo-Halo & Arabica Roasters',
                    'cuisine' => 'Filipino Merienda & Specialty Coffee',
                    'meal_type' => 'cafe',
                    'neighborhood' => 'Salcedo Village',
                    'proximity_label' => $proximityLabel,
                    'dietary_tags' => ['vegetarian', 'kid_friendly', 'local_specialty'],
                    'price_tier' => 'budget',
                    'notes' => 'Single-origin Benguet pour-over coffee, shaved-milk halo-halo, and bibingka.',
                ],
            ];
        }

        if ($country === 'SG' || str_contains($titleLower, 'singapore')) {
            return [
                [
                    'id' => 'food-sg-breakfast-1',
                    'name' => 'Heritage Kaya Toast & Kopi Nanyang Kopitiam',
                    'suggested_title' => 'Breakfast at Heritage Kaya Toast Kopitiam',
                    'cuisine' => 'Singaporean Kopitiam Breakfast',
                    'meal_type' => 'breakfast',
                    'neighborhood' => 'Chinatown / Bugis',
                    'proximity_label' => $proximityLabel,
                    'dietary_tags' => ['vegetarian', 'halal', 'kid_friendly', 'local_specialty'],
                    'price_tier' => 'budget',
                    'notes' => 'Charcoal-grilled coconut kaya toast, soft-boiled eggs, and traditional pulled kopi.',
                ],
                [
                    'id' => 'food-sg-lunch-1',
                    'name' => 'Maxwell & Lau Pa Sat Hawker Pavilion',
                    'suggested_title' => 'Lunch at Heritage Hawker Pavilion',
                    'cuisine' => 'Singaporean Hawker Classics',
                    'meal_type' => 'lunch',
                    'neighborhood' => 'Downtown Core / Marina',
                    'proximity_label' => $proximityLabel,
                    'dietary_tags' => ['halal', 'vegetarian', 'kid_friendly', 'local_specialty'],
                    'price_tier' => 'budget',
                    'notes' => 'Hainanese chicken rice, halal nasi padang stalls, and vegetarian thunder tea rice.',
                ],
                [
                    'id' => 'food-sg-dinner-1',
                    'name' => 'Peranakan Nyonya & Straits Seafood Kitchen',
                    'suggested_title' => 'Dinner at Peranakan Nyonya Kitchen',
                    'cuisine' => 'Peranakan & Straits Cuisine',
                    'meal_type' => 'dinner',
                    'neighborhood' => 'Katong / Joo Chiat',
                    'proximity_label' => $proximityLabel,
                    'dietary_tags' => ['kid_friendly', 'local_specialty'],
                    'price_tier' => 'moderate',
                    'notes' => 'Braised ayam buah keluak, non-spicy nyonya chap chye, and family round tables.',
                ],
                [
                    'id' => 'food-sg-cafe-1',
                    'name' => 'Tiong Bahru Pandan Chiffon & Espresso Bakery',
                    'suggested_title' => 'Cafe Break at Tiong Bahru Pandan Bakery',
                    'cuisine' => 'Artisanal Bakery & Southeast Asian Desserts',
                    'meal_type' => 'cafe',
                    'neighborhood' => 'Tiong Bahru',
                    'proximity_label' => $proximityLabel,
                    'dietary_tags' => ['vegetarian', 'kid_friendly', 'local_specialty'],
                    'price_tier' => 'budget',
                    'notes' => 'Light pandan chiffon cake, gula melaka cold brew, and step-free entrance.',
                ],
            ];
        }

        $cityLabel = trim($trip->title) !== '' ? trim($trip->title) : 'Destination';

        return [
            [
                'id' => 'food-gen-breakfast-1',
                'name' => "{$cityLabel} Artisanal Morning Bakery & Roastery",
                'suggested_title' => "Breakfast at {$cityLabel} Morning Bakery",
                'cuisine' => 'Local Bakery & Specialty Coffee',
                'meal_type' => 'breakfast',
                'neighborhood' => "Central {$cityLabel}",
                'proximity_label' => $proximityLabel,
                'dietary_tags' => ['vegetarian', 'kid_friendly', 'local_specialty'],
                'price_tier' => 'budget',
                'notes' => 'Freshly baked morning pastries, fruit bowls, and espresso within an easy morning stroll.',
            ],
            [
                'id' => 'food-gen-lunch-1',
                'name' => "{$cityLabel} Market Hall & Neighborhood Bistro",
                'suggested_title' => "Lunch at {$cityLabel} Market Hall Bistro",
                'cuisine' => 'Regional Market Cuisine & Sandwiches',
                'meal_type' => 'lunch',
                'neighborhood' => "Old Town / Cultural Quarter ({$cityLabel})",
                'proximity_label' => $proximityLabel,
                'dietary_tags' => ['vegetarian', 'halal', 'kid_friendly', 'local_specialty'],
                'price_tier' => 'moderate',
                'notes' => 'Casual indoor food hall with regional hot dishes, vegetarian bowls, and quick counter seating.',
            ],
            [
                'id' => 'food-gen-dinner-1',
                'name' => "{$cityLabel} Heritage Kitchen & Family Brasserie",
                'suggested_title' => "Dinner at {$cityLabel} Heritage Brasserie",
                'cuisine' => 'Traditional Regional Dinner & Grill',
                'meal_type' => 'dinner',
                'neighborhood' => "Dining District ({$cityLabel})",
                'proximity_label' => $proximityLabel,
                'dietary_tags' => ['kid_friendly', 'halal', 'vegetarian', 'local_specialty'],
                'price_tier' => 'moderate',
                'notes' => 'Relaxed evening dining with signature local dishes, English menu, and comfortable group seating.',
            ],
            [
                'id' => 'food-gen-cafe-1',
                'name' => "{$cityLabel} Botanical Courtyard Cafe & Patisserie",
                'suggested_title' => "Coffee Break at {$cityLabel} Courtyard Cafe",
                'cuisine' => 'Specialty Cafe & Local Desserts',
                'meal_type' => 'cafe',
                'neighborhood' => "Museum & Park District ({$cityLabel})",
                'proximity_label' => $proximityLabel,
                'dietary_tags' => ['vegetarian', 'kid_friendly'],
                'price_tier' => 'budget',
                'notes' => 'Quiet afternoon recharge stop with local pastries, herbal teas, and shaded seating.',
            ],
        ];
    }
}
