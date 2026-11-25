<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('travel_documents', function (Blueprint $table): void {
            $table->string('file_path', 512)->nullable()->after('access_policy');
            $table->string('original_filename', 255)->nullable()->after('file_path');
            $table->string('mime_type', 120)->nullable()->after('original_filename');
            $table->unsignedBigInteger('file_size_bytes')->nullable()->after('mime_type');
            $table->boolean('file_encrypted')->default(true)->after('file_size_bytes');
        });

        Schema::table('booking_imports', function (Blueprint $table): void {
            $table->string('file_path', 512)->nullable()->after('source');
            $table->string('original_filename', 255)->nullable()->after('file_path');
            $table->string('mime_type', 120)->nullable()->after('original_filename');
            $table->unsignedBigInteger('file_size_bytes')->nullable()->after('mime_type');
            $table->boolean('file_encrypted')->default(true)->after('file_size_bytes');
        });
    }

    public function down(): void
    {
        Schema::table('travel_documents', function (Blueprint $table): void {
            $table->dropColumn([
                'file_path',
                'original_filename',
                'mime_type',
                'file_size_bytes',
                'file_encrypted',
            ]);
        });

        Schema::table('booking_imports', function (Blueprint $table): void {
            $table->dropColumn([
                'file_path',
                'original_filename',
                'mime_type',
                'file_size_bytes',
                'file_encrypted',
            ]);
        });
    }
};
