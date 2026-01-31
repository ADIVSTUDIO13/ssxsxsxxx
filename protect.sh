#!/bin/bash

# ==================================================
# PROTECT BY Ardi - PANEL PROTECTION SCRIPT
# Created by: Ardi
# Version: 3.1 (Added Custom Protection Text Feature)
# ==================================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
echo "=================================================="
echo "           PROTECT BY Ardi INSTALLER"
echo "           Version 3.1 (Custom Text Feature)"
echo "=================================================="
echo -e "${NC}"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

print_error() {
    echo -e "${RED}[✗] $1${NC}"
}

print_info() {
    echo -e "${CYAN}[i] $1${NC}"
}

# Check if we're in the correct directory
if [[ ! -d "/var/www/pterodactyl" ]]; then
    print_error "Pterodactyl panel not found in /var/www/pterodactyl"
    print_error "Please run this script from your Pterodactyl installation directory"
    exit 1
fi

# ==================================================
# INPUT ADMIN ID
# ==================================================
echo -e "${YELLOW}Masukkan ID User yang akan dijadikan SUPER ADMIN.${NC}"
echo -e "${YELLOW}User ini memiliki akses penuh (Bypass limit 100%, Force Delete User).${NC}"
read -p "Masukkan ID Admin Utama (Default: 1): " INPUT_ID

# Set default ke 1 jika kosong
ADMIN_ID=${INPUT_ID:-1}

echo ""
print_status "Proteksi akan diinstall dengan SUPER ADMIN ID: ${BLUE}$ADMIN_ID${NC}"
echo ""

# ==================================================
# CUSTOM PROTECTION TEXT CONFIGURATION
# ==================================================
echo -e "${PURPLE}==================================================${NC}"
echo -e "${PURPLE}          KONFIGURASI TEKS PROTEKSI${NC}"
echo -e "${PURPLE}==================================================${NC}"
echo ""
echo -e "${YELLOW}Anda dapat mengustomisasi teks proteksi yang akan muncul di panel.${NC}"
echo -e "${YELLOW}Biarkan kosong untuk menggunakan teks default.${NC}"
echo ""

# Default protection texts
DEFAULT_TEXTS=(
    "access_denied_general=🚫 Akses ditolak! Hanya admin utama yang dapat mengakses."
    "delete_user_denied=❌ Hanya admin utama yang dapat menghapus user lain! © Protect by Ardi"
    "delete_server_denied=Akses ditolak: Anda hanya dapat menghapus server milik Anda sendiri @ PROTECT BY Ardi"
    "location_denied=Protect by Ardi - Akses ditolak"
    "nodes_denied=🚫 Akses ditolak! Hanya admin utama yang dapat membuka menu Nodes. © Protect by Ardi"
    "nests_denied=🚫 Akses ditolak! Hanya admin utama yang bisa membuka menu Nests."
    "settings_denied=Protect by Ardi - Akses ditolak❌"
    "cpu_unlimited_denied=🚫 Gagal: Server tidak boleh Unlimited CPU (0). Mohon isi angka spesifik."
    "cpu_limit_denied=🚫 Gagal: Anda hanya diizinkan membuat server dengan maks CPU 100%."
    "server_view_denied=Akses ditolak: Anda tidak memiliki hak akses ke server ini. © Protect by Ardi"
    "admin_demote_denied=🚫 Tidak dapat menubah hak admin pengguna ini. Hanya admin utama yang memiliki izin."
    "warning_popup=⚠️ PERINGATAN: Dilarang menggunakan script yang menyebabkan cpu 100% dan bandwith yang tinggi, jika ketahuan maka akan di delete"
    "protect_signature=© Protect by Ardi"
)

# Array untuk menyimpan teks kustom
declare -A CUSTOM_TEXTS

# Load existing custom texts if config file exists
CONFIG_FILE="/var/www/pterodactyl/storage/framework/cache/protect_texts.json"
if [[ -f "$CONFIG_FILE" ]]; then
    print_info "Mengambil konfigurasi teks yang sudah ada..."
    while IFS='=' read -r key value; do
        CUSTOM_TEXTS["$key"]="$value"
    done < <(jq -r 'to_entries[] | "\(.key)=\(.value)"' "$CONFIG_FILE" 2>/dev/null || echo "")
fi

# Function to get custom text
get_custom_text() {
    local key="$1"
    local default="$2"
    
    if [[ -n "${CUSTOM_TEXTS[$key]}" ]]; then
        echo "${CUSTOM_TEXTS[$key]}"
    else
        echo "$default"
    fi
}

echo -e "${CYAN}Ingin mengustomisasi teks proteksi? (y/n)${NC}"
read -p "Pilihan: " CUSTOMIZE_CHOICE

if [[ "$CUSTOMIZE_CHOICE" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${YELLOW}Masukkan teks kustom untuk setiap pesan proteksi:${NC}"
    echo -e "${YELLOW}(Tekan Enter untuk menggunakan teks default)${NC}"
    echo ""
    
    for text_entry in "${DEFAULT_TEXTS[@]}"; do
        key="${text_entry%%=*}"
        default_value="${text_entry#*=}"
        
        current_value=$(get_custom_text "$key" "$default_value")
        
        echo -e "${BLUE}Key: $key${NC}"
        echo -e "Default: $default_value"
        echo -e "Saat ini: $current_value"
        read -p "Teks baru: " new_text
        
        if [[ -n "$new_text" ]]; then
            CUSTOM_TEXTS["$key"]="$new_text"
            print_status "Teks untuk '$key' diperbarui"
        elif [[ -z "${CUSTOM_TEXTS[$key]}" ]]; then
            CUSTOM_TEXTS["$key"]="$default_value"
        fi
        echo ""
    done
    
    # Save custom texts to config file
    mkdir -p "$(dirname "$CONFIG_FILE")"
    echo "{" > "$CONFIG_FILE"
    local first=true
    for key in "${!CUSTOM_TEXTS[@]}"; do
        if [[ "$first" == true ]]; then
            first=false
        else
            echo "," >> "$CONFIG_FILE"
        fi
        echo -n "  \"$key\": \"${CUSTOM_TEXTS[$key]//\"/\\\"}\"" >> "$CONFIG_FILE"
    done
    echo -e "\n}" >> "$CONFIG_FILE"
    
    print_status "Konfigurasi teks proteksi disimpan di: $CONFIG_FILE"
else
    # Use default texts
    for text_entry in "${DEFAULT_TEXTS[@]}"; do
        key="${text_entry%%=*}"
        CUSTOM_TEXTS["$key"]="${text_entry#*=}"
    done
    print_info "Menggunakan teks proteksi default"
fi

echo ""

# Backup directory
BACKUP_DIR="/var/www/pterodactyl/backups/protect_Ardi_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Function to create backup
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cp "$file" "$BACKUP_DIR/"
        print_status "Backed up: $(basename "$file")"
    fi
}

# Function to replace file content with Admin ID and custom text injection
replace_file() {
    local file="$1"
    local content="$2"
    local description="$3"
    
    # Inject Real Admin ID into the placeholder __BP_ADMIN_ID__
    content="${content//__BP_ADMIN_ID__/$ADMIN_ID}"
    
    # Inject custom texts
    for key in "${!CUSTOM_TEXTS[@]}"; do
        placeholder="__PROTECT_TEXT_${key}__"
        content="${content//$placeholder/${CUSTOM_TEXTS[$key]}}"
    done
    
    backup_file "$file"
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$file")"
    
    # Write content to file
    echo "$content" > "$file"
    
    if [[ $? -eq 0 ]]; then
        print_status "Installed: $description"
    else
        print_error "Failed to install: $description"
        return 1
    fi
}

# ==================================================
# CLEANUP FUNCTION (DELETE ANTI DDOS)
# ==================================================
cleanup_security_services() {
    print_warning "Menghapus sisa-sisa Anti-DDoS / Firewall Rules..."
    
    # Stop & Remove Services
    systemctl stop Ardi-sentinel Ardi-botfight 2>/dev/null
    systemctl disable Ardi-sentinel Ardi-botfight 2>/dev/null
    rm -f /etc/systemd/system/Ardi-sentinel.service
    rm -f /etc/systemd/system/Ardi-botfight.service
    rm -f /usr/local/bin/Ardi-sentinel
    rm -f /usr/local/bin/Ardi-botfight
    systemctl daemon-reload
    
    # Flush IPTables (Restore Network Access)
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -F
    iptables -X
    
    if command -v netfilter-persistent &> /dev/null; then
        netfilter-persistent save >/dev/null 2>&1
    fi
    
    print_status "Network & Firewall telah dibersihkan."
}

# ==================================================
# 1. ANTI DELETE SERVER (SERVICE) - WITH CUSTOM TEXT
# ==================================================

SERVER_DELETION_SERVICE='<?php

namespace Pterodactyl\Services\Servers;

use Illuminate\Support\Facades\Auth;
use Pterodactyl\Exceptions\DisplayException;
use Illuminate\Http\Response;
use Pterodactyl\Models\Server;
use Illuminate\Support\Facades\Log;
use Illuminate\Database\ConnectionInterface;
use Pterodactyl\Repositories\Wings\DaemonServerRepository;
use Pterodactyl\Services\Databases\DatabaseManagementService;
use Pterodactyl\Exceptions\Http\Connection\DaemonConnectionException;

class ServerDeletionService
{
    protected bool $force = false;

    public function __construct(
        private ConnectionInterface $connection,
        private DaemonServerRepository $daemonServerRepository,
        private DatabaseManagementService $databaseManagementService
    ) {
    }

    public function withForce(bool $bool = true): self
    {
        $this->force = $bool;
        return $this;
    }

    public function handle(Server $server): void
    {
        $user = Auth::user();

        // 🔒 Proteksi: Hanya Admin ID __BP_ADMIN_ID__ yang bisa hapus server orang lain.
        if ($user) {
            if ($user->id !== __BP_ADMIN_ID__) {
                $ownerId = $server->owner_id
                    ?? $server->user_id
                    ?? ($server->owner?->id ?? null)
                    ?? ($server->user?->id ?? null);

                if ($ownerId === null) {
                    throw new DisplayException("Akses ditolak: informasi pemilik server tidak tersedia.");
                }

                if ($ownerId !== $user->id) {
                    throw new DisplayException("__PROTECT_TEXT_delete_server_denied__");
                }
            }
        }

        try {
            $this->daemonServerRepository->setServer($server)->delete();
        } catch (DaemonConnectionException $exception) {
            if (!$this->force && $exception->getStatusCode() !== Response::HTTP_NOT_FOUND) {
                throw $exception;
            }
            Log::warning($exception);
        }

        $this->connection->transaction(function () use ($server) {
            foreach ($server->databases as $database) {
                try {
                    $this->databaseManagementService->delete($database);
                } catch (\Exception $exception) {
                    if (!$this->force) {
                        throw $exception;
                    }
                    $database->delete();
                    Log::warning($exception);
                }
            }
            $server->delete();
        });
    }
}'

# ==================================================
# 2. ANTI DELETE USER (WITH FORCE DELETE) - WITH CUSTOM TEXT
# ==================================================

USER_CONTROLLER='<?php

namespace Pterodactyl\Http\Controllers\Admin;

use Illuminate\View\View;
use Illuminate\Http\Request;
use Pterodactyl\Models\User;
use Pterodactyl\Models\Model;
use Illuminate\Support\Collection;
use Illuminate\Http\RedirectResponse;
use Prologue\Alerts\AlertsMessageBag;
use Spatie\QueryBuilder\QueryBuilder;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Exceptions\DisplayException;
use Pterodactyl\Http\Controllers\Controller;
use Illuminate\Contracts\Translation\Translator;
use Pterodactyl\Services\Users\UserUpdateService;
use Pterodactyl\Traits\Helpers\AvailableLanguages;
use Pterodactyl\Services\Users\UserCreationService;
use Pterodactyl\Services\Users\UserDeletionService;
use Pterodactyl\Services\Servers\ServerDeletionService;
use Pterodactyl\Http\Requests\Admin\UserFormRequest;
use Pterodactyl\Http\Requests\Admin\NewUserFormRequest;
use Pterodactyl\Contracts\Repository\UserRepositoryInterface;

class UserController extends Controller
{
    use AvailableLanguages;

    public function __construct(
        protected AlertsMessageBag $alert,
        protected UserCreationService $creationService,
        protected UserDeletionService $deletionService,
        protected ServerDeletionService $serverDeletionService,
        protected Translator $translator,
        protected UserUpdateService $updateService,
        protected UserRepositoryInterface $repository,
        protected ViewFactory $view
    ) {
    }

    public function index(Request $request): View
    {
        $users = QueryBuilder::for(
            User::query()->select("users.*")
                ->selectRaw("COUNT(DISTINCT(subusers.id)) as subuser_of_count")
                ->selectRaw("COUNT(DISTINCT(servers.id)) as servers_count")
                ->leftJoin("subusers", "subusers.user_id", "=", "users.id")
                ->leftJoin("servers", "servers.owner_id", "=", "users.id")
                ->groupBy("users.id")
        )
            ->allowedFilters(["username", "email", "uuid"])
            ->allowedSorts(["id", "uuid"])
            ->paginate(50);

        return $this->view->make("admin.users.index", ["users" => $users]);
    }

    public function create(): View
    {
        return $this->view->make("admin.users.new", [
            "languages" => $this->getAvailableLanguages(true),
        ]);
    }

    public function view(User $user): View
    {
        return $this->view->make("admin.users.view", [
            "user" => $user,
            "languages" => $this->getAvailableLanguages(true),
        ]);
    }

    public function delete(Request $request, User $user): RedirectResponse
    {
        // === PROTEKSI HAPUS USER ===
        if ($request->user()->id !== __BP_ADMIN_ID__) {
            throw new DisplayException("__PROTECT_TEXT_delete_user_denied__");
        }

        if ($request->user()->id === $user->id) {
            throw new DisplayException("Anda tidak dapat menghapus akun Anda sendiri saat sedang login.");
        }

        // === FORCE DELETE LOGIC (SUPER ADMIN ONLY) ===
        if ($user->servers()->count() > 0) {
            foreach ($user->servers as $server) {
                try {
                    $this->serverDeletionService->withForce(true)->handle($server);
                } catch (\Exception $e) {}
            }
        }

        $this->deletionService->handle($user);
        
        $this->alert->success("User dan seluruh servernya berhasil dihapus.")->flash();
        return redirect()->route("admin.users");
    }

    public function store(NewUserFormRequest $request): RedirectResponse
    {
        $user = $this->creationService->handle($request->normalize());
        $this->alert->success($this->translator->get("admin/user.notices.account_created"))->flash();
        return redirect()->route("admin.users.view", $user.id);
    }

    public function update(UserFormRequest $request, User $user): RedirectResponse
    {
        $restrictedFields = ["email", "first_name", "last_name", "password"];
        foreach ($restrictedFields as $field) {
            if ($request->filled($field) && $request->user()->id !== __BP_ADMIN_ID__) {
                throw new DisplayException("⚠️ Data hanya bisa diubah oleh admin utama.");
            }
        }
        if ($user->root_admin && $request->user()->id !== __BP_ADMIN_ID__) {
            throw new DisplayException("__PROTECT_TEXT_admin_demote_denied__");
        }

        $this->updateService->setUserLevel(User::USER_LEVEL_ADMIN)->handle($user, $request->normalize());
        $this->alert->success(trans("admin/user.notices.account_updated"))->flash();
        return redirect()->route("admin.users.view", $user.id);
    }

    public function json(Request $request): Model|Collection
    {
        $users = QueryBuilder::for(User::query())->allowedFilters(["email"])->paginate(25);
        if ($request->query("user_id")) {
            $user = User::query()->findOrFail($request->input("user_id"));
            $user->md5 = md5(strtolower($user->email));
            return $user;
        }
        return $users->map(function ($item) {
            $item->md5 = md5(strtolower($item->email));
            return $item;
        });
    }
}'

# ==================================================
# 3. ANTI INTIP LOCATION - WITH CUSTOM TEXT
# ==================================================

LOCATION_CONTROLLER='<?php

namespace Pterodactyl\Http\Controllers\Admin;

use Illuminate\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Auth;
use Pterodactyl\Models\Location;
use Prologue\Alerts\AlertsMessageBag;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Exceptions\DisplayException;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Http\Requests\Admin\LocationFormRequest;
use Pterodactyl\Services\Locations\LocationUpdateService;
use Pterodactyl\Services\Locations\LocationCreationService;
use Pterodactyl\Services\Locations\LocationDeletionService;
use Pterodactyl\Contracts\Repository\LocationRepositoryInterface;

class LocationController extends Controller
{
    public function __construct(
        protected AlertsMessageBag $alert,
        protected LocationCreationService $creationService,
        protected LocationDeletionService $deletionService,
        protected LocationRepositoryInterface $repository,
        protected LocationUpdateService $updateService,
        protected ViewFactory $view
    ) {}

    public function index(): View {
        if (Auth::user()->id !== __BP_ADMIN_ID__) abort(403, "__PROTECT_TEXT_location_denied__");
        return $this->view->make("admin.locations.index", ["locations" => $this->repository->getAllWithDetails()]);
    }

    public function view(int $id): View {
        if (Auth::user()->id !== __BP_ADMIN_ID__) abort(403, "__PROTECT_TEXT_location_denied__");
        return $this->view->make("admin.locations.view", ["location" => $this->repository->getWithNodes($id)]);
    }

    public function create(LocationFormRequest $request): RedirectResponse {
        if (Auth::user()->id !== __BP_ADMIN_ID__) abort(403, "__PROTECT_TEXT_location_denied__");
        $location = $this->creationService->handle($request->normalize());
        $this->alert->success("Location was created successfully.")->flash();
        return redirect()->route("admin.locations.view", $location->id);
    }

    public function update(LocationFormRequest $request, Location $location): RedirectResponse {
        if (Auth::user()->id !== __BP_ADMIN_ID__) abort(403, "__PROTECT_TEXT_location_denied__");
        if ($request->input("action") === "delete") return $this->delete($location);
        $this->updateService->handle($location->id, $request->normalize());
        $this->alert->success("Location was updated successfully.")->flash();
        return redirect()->route("admin.locations.view", $location->id);
    }

    public function delete(Location $location): RedirectResponse {
        if (Auth::user()->id !== __BP_ADMIN_ID__) abort(403, "__PROTECT_TEXT_location_denied__");
        try {
            $this->deletionService->handle($location->id);
            return redirect()->route("admin.locations");
        } catch (DisplayException $ex) {
            $this->alert->danger($ex->getMessage())->flash();
        }
        return redirect()->route("admin.locations.view", $location->id);
    }
}'

# ==================================================
# 4. ANTI INTIP NODES - WITH CUSTOM TEXT
# ==================================================

NODE_CONTROLLER='<?php

namespace Pterodactyl\Http\Controllers\Admin\Nodes;

use Illuminate\View\View;
use Illuminate\Http\Request;
use Pterodactyl\Models\Node;
use Spatie\QueryBuilder\QueryBuilder;
use Pterodactyl\Http\Controllers\Controller;
use Illuminate\Contracts\View\Factory as ViewFactory;
use Illuminate\Support\Facades\Auth;

class NodeController extends Controller
{
    public function __construct(private ViewFactory $view) {}

    public function index(Request $request): View
    {
        if (Auth::user()->id !== __BP_ADMIN_ID__) {
            abort(403, "__PROTECT_TEXT_nodes_denied__");
        }

        $nodes = QueryBuilder::for(Node::query()->with("location")->withCount("servers"))
            ->allowedFilters(["uuid", "name"])
            ->allowedSorts(["id"])
            ->paginate(25);

        return $this->view->make("admin.nodes.index", ["nodes" => $nodes]);
    }
}'

# ==================================================
# 5. ANTI INTIP NEST - WITH CUSTOM TEXT
# ==================================================

NEST_CONTROLLER='<?php

namespace Pterodactyl\Http\Controllers\Admin\Nests;

use Illuminate\View\View;
use Illuminate\Http\RedirectResponse;
use Prologue\Alerts\AlertsMessageBag;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Services\Nests\NestUpdateService;
use Pterodactyl\Services\Nests\NestCreationService;
use Pterodactyl\Services\Nests\NestDeletionService;
use Pterodactyl\Contracts\Repository\NestRepositoryInterface;
use Pterodactyl\Http\Requests\Admin\Nest\StoreNestFormRequest;
use Illuminate\Support\Facades\Auth;

class NestController extends Controller
{
    public function __construct(
        protected AlertsMessageBag $alert,
        protected NestCreationService $nestCreationService,
        protected NestDeletionService $nestDeletionService,
        protected NestRepositoryInterface $repository,
        protected NestUpdateService $nestUpdateService,
        protected ViewFactory $view
    ) {}

    public function index(): View {
        if (Auth::user()->id !== __BP_ADMIN_ID__) abort(403, "__PROTECT_TEXT_nests_denied__");
        return $this->view->make("admin.nests.index", ["nests" => $this->repository->getWithCounts()]);
    }

    public function create(): View { return $this->view->make("admin.nests.new"); }

    public function store(StoreNestFormRequest $request): RedirectResponse {
        $nest = $this->nestCreationService->handle($request->normalize());
        $this->alert->success(trans("admin/nests.notices.created", ["name" => htmlspecialchars($nest->name)]))->flash();
        return redirect()->route("admin.nests.view", $nest->id);
    }

    public function view(int $nest): View {
        return $this->view->make("admin.nests.view", ["nest" => $this->repository->getWithEggServers($nest)]);
    }

    public function update(StoreNestFormRequest $request, int $nest): RedirectResponse {
        $this->nestUpdateService->handle($nest, $request->normalize());
        $this->alert->success(trans("admin/nests.notices.updated"))->flash();
        return redirect()->route("admin.nests.view", $nest);
    }

    public function destroy(int $nest): RedirectResponse {
        $this->nestDeletionService->handle($nest);
        $this->alert->success(trans("admin/nests.notices.deleted"))->flash();
        return redirect()->route("admin.nests");
    }
}'

# ==================================================
# 6. ANTI INTIP SETTINGS - WITH CUSTOM TEXT
# ==================================================

SETTINGS_CONTROLLER='<?php

namespace Pterodactyl\Http\Controllers\Admin\Settings;

use Illuminate\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Auth;
use Prologue\Alerts\AlertsMessageBag;
use Illuminate\Contracts\Console\Kernel;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Traits\Helpers\AvailableLanguages;
use Pterodactyl\Services\Helpers\SoftwareVersionService;
use Pterodactyl\Contracts\Repository\SettingsRepositoryInterface;
use Pterodactyl\Http\Requests\Admin\Settings\BaseSettingsFormRequest;

class IndexController extends Controller
{
    use AvailableLanguages;

    public function __construct(
        private AlertsMessageBag $alert,
        private Kernel $kernel,
        private SettingsRepositoryInterface $settings,
        private SoftwareVersionService $versionService,
        private ViewFactory $view
    ) {}

    public function index(): View {
        if (Auth::user()->id !== __BP_ADMIN_ID__) abort(403, "__PROTECT_TEXT_settings_denied__");
        return $this->view->make("admin.settings.index", [
            "version" => $this->versionService,
            "languages" => $this->getAvailableLanguages(true),
        ]);
    }

    public function update(BaseSettingsFormRequest $request): RedirectResponse {
        if (Auth::user()->id !== __BP_ADMIN_ID__) abort(403, "__PROTECT_TEXT_settings_denied__");
        foreach ($request->normalize() as $key => $value) {
            $this->settings->set("settings::" . $key, $value);
        }
        $this->kernel->call("queue:restart");
        $this->alert->success("Panel settings have been updated successfully.")->flash();
        return redirect()->route("admin.settings");
    }
}'

# ==================================================
# 7. SERVER CONTROLLER (CPU LIMIT FIX + POPUP) - WITH CUSTOM TEXT
# ==================================================

SERVER_CONTROLLER='<?php

namespace Pterodactyl\Http\Controllers\Admin\Servers;

use Illuminate\View\View;
use Illuminate\Http\Request;
use Pterodactyl\Models\Server;
use Illuminate\Http\RedirectResponse;
use Prologue\Alerts\AlertsMessageBag;
use Spatie\QueryBuilder\QueryBuilder;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Services\Servers\ServerDeletionService;
use Pterodactyl\Services\Servers\ServerCreationService;
use Pterodactyl\Http\Requests\Admin\Server\StoreServerFormRequest;
use Pterodactyl\Exceptions\DisplayException;
use Pterodactyl\Models\Nest;
use Pterodactyl\Models\Node;

class ServerController extends Controller
{
    public function __construct(
        protected AlertsMessageBag $alert,
        protected ServerCreationService $creationService,
        protected ServerDeletionService $deletionService,
        protected ViewFactory $view
    ) {
    }

    public function index(Request $request): View
    {
        $query = Server::query()->with("node", "user", "allocation");

        // 🔒 FITUR: Filter Server List
        if ($request->user()->id !== __BP_ADMIN_ID__) {
            $userId = $request->user()->id;
            $query->where(function ($q) use ($userId) {
                $q->where("owner_id", $userId)
                  ->orWhereHas("subusers", function ($sub) use ($userId) {
                      $sub->where("user_id", $userId);
                  });
            });
        }

        $serverList = QueryBuilder::for($query)
            ->allowedFilters(["name", "uuid", "owner_id", "external_id"])
            ->allowedSorts(["id", "name", "uuid"])
            ->paginate(25);

        return $this->view->make("admin.servers.index", [
            "servers" => $serverList,
        ]);
    }

    public function create(): View
    {
        return $this->view->make("admin.servers.new", [
            "locations" => Node::query()->with("location")->get()->map(function ($node) {
                return $node->location;
            })->unique("id"),
            "nests" => Nest::query()->with("eggs")->get(),
        ]);
    }

    public function store(StoreServerFormRequest $request): RedirectResponse
    {
        $cpu = (int) $request->input("cpu");

        // 1. GLOBAL RULE: CPU tidak boleh 0 (Unlimited) untuk SIAPAPUN (Termasuk Admin)
        if ($cpu === 0) {
            throw new DisplayException("__PROTECT_TEXT_cpu_unlimited_denied__");
        }

        // 2. USER RULE: Jika BUKAN Super Admin, CPU maksimal 100%
        if ($request->user()->id !== __BP_ADMIN_ID__) {
             if ($cpu > 100) {
                 throw new DisplayException("__PROTECT_TEXT_cpu_limit_denied__");
             }
        }

        try {
            $server = $this->creationService->handle($request->normalize(), $request->all());
            $this->alert->success(trans("admin/server.alerts.server_created"))->flash();
            return redirect()->route("admin.servers.view", $server->id);
        } catch (\Exception $exception) {
            $this->alert->danger($exception->getMessage())->flash();
            return redirect()->route("admin.servers.new");
        }
    }

    public function view(Server $server): View
    {
        // 🔒 FITUR: Cek akses View Detail
        $user = request()->user();
        $isOwner = $server->owner_id === $user->id;
        $isSubuser = $server->subusers()->where("user_id", $user->id)->exists();
        $isSuperAdmin = $user->id === __BP_ADMIN_ID__;

        if (!$isSuperAdmin && !$isOwner && !$isSubuser) {
             abort(403, "__PROTECT_TEXT_server_view_denied__");
        }

        // 🔔 FITUR: POPUP PERINGATAN (FLASH INFO)
        if (!$isSuperAdmin) {
            $this->alert->danger("__PROTECT_TEXT_warning_popup__")->flash();
        }

        return $this->view->make("admin.servers.view", [
            "server" => $server,
        ]);
    }

    public function delete(Request $request, Server $server): RedirectResponse
    {
        // 🔒 FITUR: Cek akses Delete (Hanya ID __BP_ADMIN_ID__ atau Owner Asli)
        if ($request->user()->id !== __BP_ADMIN_ID__ && $server->owner_id !== $request->user()->id) {
             throw new DisplayException("Akses ditolak: Anda tidak memiliki izin menghapus server ini.");
        }

        try {
            $this->deletionService->withForce($request->filled("force"))->handle($server);
            $this->alert->success("Server berhasil dihapus.")->flash();
        } catch (\Exception $exception) {
            $this->alert->danger($exception->getMessage())->flash();
        }

        return redirect()->route("admin.servers");
    }
}'

# ==================================================
# 8. ADMIN PANEL CONFIGURATION CONTROLLER
# ==================================================

ADMIN_PROTECT_CONTROLLER='<?php

namespace Pterodactyl\Http\Controllers\Admin\Protect;

use Illuminate\View\View;
use Illuminate\Http\Request;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Auth;
use Prologue\Alerts\AlertsMessageBag;
use Pterodactyl\Http\Controllers\Controller;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\Factory as ViewFactory;

class ProtectConfigController extends Controller
{
    public function __construct(
        protected AlertsMessageBag $alert,
        protected ViewFactory $view
    ) {}

    public function index(): View
    {
        // Hanya super admin yang bisa akses
        if (Auth::user()->id !== ' . $ADMIN_ID . ') {
            abort(403, "Akses ditolak: Hanya super admin yang bisa mengakses konfigurasi proteksi.");
        }

        $configFile = storage_path("framework/cache/protect_texts.json");
        $configs = [];
        
        if (file_exists($configFile)) {
            $configs = json_decode(file_get_contents($configFile), true) ?: [];
        }

        // Default texts jika file tidak ada
        $defaultTexts = [
            "access_denied_general" => "🚫 Akses ditolak! Hanya admin utama yang dapat mengakses.",
            "delete_user_denied" => "❌ Hanya admin utama yang dapat menghapus user lain! © Protect by Ardi",
            "delete_server_denied" => "Akses ditolak: Anda hanya dapat menghapus server milik Anda sendiri @ PROTECT BY Ardi",
            "location_denied" => "Protect by Ardi - Akses ditolak",
            "nodes_denied" => "🚫 Akses ditolak! Hanya admin utama yang dapat membuka menu Nodes. © Protect by Ardi",
            "nests_denied" => "🚫 Akses ditolak! Hanya admin utama yang bisa membuka menu Nests.",
            "settings_denied" => "Protect by Ardi - Akses ditolak❌",
            "cpu_unlimited_denied" => "🚫 Gagal: Server tidak boleh Unlimited CPU (0). Mohon isi angka spesifik.",
            "cpu_limit_denied" => "🚫 Gagal: Anda hanya diizinkan membuat server dengan maks CPU 100%.",
            "server_view_denied" => "Akses ditolak: Anda tidak memiliki hak akses ke server ini. © Protect by Ardi",
            "admin_demote_denied" => "🚫 Tidak dapat menurunkan hak admin pengguna ini. Hanya admin utama yang memiliki izin.",
            "warning_popup" => "⚠️ PERINGATAN: Dilarang menggunakan script yang menyebabkan cpu 100% dan bandwith yang tinggi, jika ketahuan maka akan di delete",
            "protect_signature" => "© Protect by Ardi"
        ];

        foreach ($defaultTexts as $key => $value) {
            if (!isset($configs[$key])) {
                $configs[$key] = $value;
            }
        }

        return $this->view->make("admin.protect.config", [
            "configs" => $configs,
            "admin_id" => ' . $ADMIN_ID . ',
        ]);
    }

    public function update(Request $request): RedirectResponse
    {
        // Hanya super admin yang bisa update
        if (Auth::user()->id !== ' . $ADMIN_ID . ') {
            abort(403, "Akses ditolak: Hanya super admin yang bisa mengubah konfigurasi proteksi.");
        }

        $configs = [];
        foreach ($request->all() as $key => $value) {
            if (strpos($key, "text_") === 0) {
                $configKey = substr($key, 5);
                $configs[$configKey] = $value;
            }
        }

        $configFile = storage_path("framework/cache/protect_texts.json");
        file_put_contents($configFile, json_encode($configs, JSON_PRETTY_PRINT));

        $this->alert->success("Konfigurasi teks proteksi berhasil diperbarui!")->flash();
        return redirect()->route("admin.protect.config");
    }

    public function reset(): RedirectResponse
    {
        // Hanya super admin yang bisa reset
        if (Auth::user()->id !== ' . $ADMIN_ID . ') {
            abort(403, "Akses ditolak: Hanya super admin yang bisa mereset konfigurasi proteksi.");
        }

        $defaultTexts = [
            "access_denied_general" => "🚫 Akses ditolak! Hanya admin utama yang dapat mengakses.",
            "delete_user_denied" => "❌ Hanya admin utama yang dapat menghapus user lain! © Protect by Ardi",
            "delete_server_denied" => "Akses ditolak: Anda hanya dapat menghapus server milik Anda sendiri @ PROTECT BY Ardi",
            "location_denied" => "Protect by Ardi - Akses ditolak",
            "nodes_denied" => "🚫 Akses ditolak! Hanya admin utama yang dapat membuka menu Nodes. © Protect by Ardi",
            "nests_denied" => "🚫 Akses ditolak! Hanya admin utama yang bisa membuka menu Nests.",
            "settings_denied" => "Protect by Ardi - Akses ditolak❌",
            "cpu_unlimited_denied" => "🚫 Gagal: Server tidak boleh Unlimited CPU (0). Mohon isi angka spesifik.",
            "cpu_limit_denied" => "🚫 Gagal: Anda hanya diizinkan membuat server dengan maks CPU 100%.",
            "server_view_denied" => "Akses ditolak: Anda tidak memiliki hak akses ke server ini. © Protect by Ardi",
            "admin_demote_denied" => "🚫 Tidak dapat menurunkan hak admin pengguna ini. Hanya admin utama yang memiliki izin.",
            "warning_popup" => "⚠️ PERINGATAN: Dilarang menggunakan script yang menyebabkan cpu 100% dan bandwith yang tinggi, jika ketahuan maka akan di delete",
            "protect_signature" => "© Protect by Ardi"
        ];

        $configFile = storage_path("framework/cache/protect_texts.json");
        file_put_contents($configFile, json_encode($defaultTexts, JSON_PRETTY_PRINT));

        $this->alert->success("Konfigurasi teks proteksi telah direset ke default!")->flash();
        return redirect()->route("admin.protect.config");
    }
}'

# ==================================================
# 9. ADMIN PANEL VIEW FILE
# ==================================================

ADMIN_PROTECT_VIEW='<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Protect by Ardi - Configuration</title>
    @include("layouts.head")
</head>
<body class="bg-gray-100">
    @include("layouts.nav")
    
    <div class="container mx-auto px-4 py-8">
        <div class="bg-white rounded-lg shadow-lg p-6">
            <div class="flex justify-between items-center mb-6">
                <h1 class="text-2xl font-bold text-gray-800">
                    🔒 Protect by Ardi - Configuration
                </h1>
                <span class="px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm font-semibold">
                    Super Admin ID: {{ $admin_id }}
                </span>
            </div>

            <div class="mb-6 p-4 bg-yellow-50 border-l-4 border-yellow-400">
                <div class="flex">
                    <div class="flex-shrink-0">
                        <svg class="h-5 w-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
                        </svg>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm text-yellow-700">
                            <strong>Note:</strong> Ubah teks proteksi yang muncul di panel. Perubahan akan diterapkan secara real-time.
                        </p>
                    </div>
                </div>
            </div>

            <form method="POST" action="{{ route("admin.protect.config.update") }}">
                @csrf
                
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    @foreach($configs as $key => $value)
                    <div class="space-y-2">
                        <label class="block text-sm font-medium text-gray-700">
                            {{ str_replace("_", " ", ucfirst($key)) }}
                        </label>
                        <textarea 
                            name="text_{{ $key }}" 
                            rows="3"
                            class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                            placeholder="Masukkan teks untuk {{ $key }}"
                        >{{ old("text_" . $key, $value) }}</textarea>
                        <p class="text-xs text-gray-500 mt-1">
                            Key: <code>{{ $key }}</code>
                        </p>
                    </div>
                    @endforeach
                </div>

                <div class="mt-8 pt-6 border-t border-gray-200">
                    <div class="flex justify-end space-x-4">
                        <a href="{{ route("admin.protect.config.reset") }}" 
                           class="inline-flex items-center px-4 py-2 bg-red-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-red-700 focus:outline-none focus:border-red-700 focus:ring ring-red-300 disabled:opacity-25 transition ease-in-out duration-150"
                           onclick="return confirm("Reset semua teks ke default?")">
                            Reset to Default
                        </a>
                        <button type="submit" 
                                class="inline-flex items-center px-4 py-2 bg-blue-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-blue-700 focus:outline-none focus:border-blue-700 focus:ring ring-blue-300 disabled:opacity-25 transition ease-in-out duration-150">
                            Save Changes
                        </button>
                    </div>
                </div>
            </form>

            <div class="mt-8 p-4 bg-gray-50 rounded-lg">
                <h3 class="text-lg font-semibold text-gray-700 mb-3">📊 Info:</h3>
                <ul class="space-y-2 text-sm text-gray-600">
                    <li>• Total teks yang dapat dikustomisasi: {{ count($configs) }}</li>
                    <li>• Super Admin ID: {{ $admin_id }}</li>
                    <li>• Config file: <code>/storage/framework/cache/protect_texts.json</code></li>
                    <li>• Semua teks akan otomatis diterapkan ke semua modul proteksi</li>
                </ul>
            </div>
        </div>
    </div>

    @include("layouts.scripts")
</body>
</html>'

# ==================================================
# ROUTE FILE CONTENT
# ==================================================

ROUTE_CONTENT='<?php

use Illuminate\Support\Facades\Route;
use Pterodactyl\Http\Controllers\Admin\Protect\ProtectConfigController;

// Protect by Ardi Routes
Route::group(["prefix" => "/protect", "as" => "admin.protect."], function () {
    Route::get("/config", [ProtectConfigController::class, "index"])
        ->name("config");
    Route::post("/config", [ProtectConfigController::class, "update"])
        ->name("config.update");
    Route::get("/config/reset", [ProtectConfigController::class, "reset"])
        ->name("config.reset");
});'

# ==================================================
# MAIN INSTALLATION
# ==================================================

echo -e "${BLUE}Starting Protect by Ardi installation...${NC}"
echo ""

# 1. Bersihkan Anti-DDoS
cleanup_security_services

# Install all protection files
print_status "Installing protection modules..."

# 2. Anti Delete Server (Service)
replace_file "/var/www/pterodactyl/app/Services/Servers/ServerDeletionService.php" "$SERVER_DELETION_SERVICE" "Anti Delete Server Protection"

# 3. Anti Delete User  
replace_file "/var/www/pterodactyl/app/Http/Controllers/Admin/UserController.php" "$USER_CONTROLLER" "Anti Delete User Protection"

# 4. Anti Intip Location
replace_file "/var/www/pterodactyl/app/Http/Controllers/Admin/LocationController.php" "$LOCATION_CONTROLLER" "Anti Intip Location Protection"

# 5. Anti Intip Nodes
replace_file "/var/www/pterodactyl/app/Http/Controllers/Admin/Nodes/NodeController.php" "$NODE_CONTROLLER" "Anti Intip Nodes Protection"

# 6. Anti Intip Nest
replace_file "/var/www/pterodactyl/app/Http/Controllers/Admin/Nests/NestController.php" "$NEST_CONTROLLER" "Anti Intip Nest Protection"

# 7. Anti Intip Settings
replace_file "/var/www/pterodactyl/app/Http/Controllers/Admin/Settings/IndexController.php" "$SETTINGS_CONTROLLER" "Anti Intip Settings Protection"

# 8. Anti Intip Server + Popup + CPU Limit (Fixed)
replace_file "/var/www/pterodactyl/app/Http/Controllers/Admin/Servers/ServerController.php" "$SERVER_CONTROLLER" "Anti Intip Server List & View"

# 9. Install Admin Panel Controller
replace_file "/var/www/pterodactyl/app/Http/Controllers/Admin/Protect/ProtectConfigController.php" "$ADMIN_PROTECT_CONTROLLER" "Protect Config Admin Controller"

# 10. Create admin view directory
mkdir -p "/var/www/pterodactyl/resources/views/admin/protect"

# 11. Install Admin Panel View
replace_file "/var/www/pterodactyl/resources/views/admin/protect/config.blade.php" "$ADMIN_PROTECT_VIEW" "Protect Config Admin View"

# 12. Add routes to web.php
ROUTE_FILE="/var/www/pterodactyl/routes/web.php"
if grep -q "ProtectConfigController" "$ROUTE_FILE"; then
    print_info "Routes already exist, skipping..."
else
    backup_file "$ROUTE_FILE"
    echo -e "\n// Protect by Ardi Routes\n$ROUTE_CONTENT" >> "$ROUTE_FILE"
    print_status "Added Protect routes to web.php"
fi

echo ""
print_status "All protection modules installed successfully!"

# Fix for DOMDocument
print_status "Checking and installing required PHP extensions..."
apt-get update -y >/dev/null 2>&1
apt-get install -y php-xml php-dom bc jq >/dev/null 2>&1

# Set proper permissions
print_status "Setting file permissions..."
chown -R www-data:www-data /var/www/pterodactyl
chmod -R 755 /var/www/pterodactyl/storage
chmod -R 755 /var/www/pterodactyl/bootstrap/cache

# Clear cache
print_status "Clearing application cache..."
cd /var/www/pterodactyl
php artisan config:cache
php artisan view:cache
php artisan route:cache
service nginx restart

echo ""
echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}    PROTECT BY Ardi INSTALLATION COMPLETE!${NC}"
echo -e "${GREEN}         Version 3.1 (Custom Text Feature)${NC}"
echo -e "${GREEN}            Created by Ardi${NC}"
echo -e "${GREEN}==================================================${NC}"
echo ""
echo -e "${YELLOW}Summary:${NC}"
echo -e "✓ Super Admin ID: ${BLUE}$ADMIN_ID${NC}"
echo -e "✓ All Anti-View & Anti-Delete Modules Active"
echo -e "✓ CPU Limit: No 0 (Everyone), Max 100% (Non-Admin)"
echo -e "✓ WARNING POPUP: ${RED}ACTIVE${NC}"
echo -e "✓ Admin Panel Config: ${GREEN}ENABLED${NC} (Akses di: /admin/protect/config)"
echo -e "✓ Custom Text Feature: ${GREEN}ENABLED${NC} (12 teks dapat dikustomisasi)"
echo ""
echo -e "${YELLOW}Backups saved to:${NC} $BACKUP_DIR"
echo ""
echo -e "${BLUE}Untuk mengubah teks proteksi:${NC}"
echo -e "1. Login sebagai Super Admin (ID: $ADMIN_ID)"
echo -e "2. Buka ${CYAN}/admin/protect/config${NC}"
echo -e "3. Ubah teks sesuai keinginan"
echo -e "4. Tekan Save Changes"
echo ""
echo -e "${BLUE}Your Pterodactyl panel is now protected by Ardi!${NC}"
echo ""