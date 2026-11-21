#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$ROOT_DIR/indice-backend"
MOBILE_DIR="$ROOT_DIR/indice_mobile"
LOG_FILE="$ROOT_DIR/logs/backend.log"
API_URL="http://localhost:8080/api"
HEALTH_URL="$API_URL/resources?size=1"
STARTUP_TIMEOUT_SECONDS=180

BACKEND_STARTED_BY_SCRIPT=false

info() { printf '\033[1;34m==> %s\033[0m\n' "$1"; }
fail() { printf '\033[1;31mErreur : %s\033[0m\n' "$1" >&2; exit 1; }

require_command() {
  command -v "$1" > /dev/null || fail "$1 est introuvable. $2"
}

check_prerequisites() {
  info "Vérification des prérequis"
  require_command java "Installez un JDK 25."
  require_command docker "Installez Docker Desktop."
  require_command flutter "Installez Flutter 3.47 ou plus récent."
  require_command curl "Installez curl."
  require_command lsof "Installez lsof."
  docker info > /dev/null 2>&1 || fail "Docker n'est pas démarré. Lancez Docker Desktop puis relancez le script."
}

check_backend_config() {
  if [[ -f "$BACKEND_DIR/src/main/resources/application-local.yaml" ]]; then
    return
  fi
  if [[ -n "${SPRING_DATASOURCE_URL:-}" && -n "${SPRING_DATASOURCE_USERNAME:-}" \
     && -n "${SPRING_DATASOURCE_PASSWORD:-}" && -n "${TWELVEDATA_API_TOKEN:-}" ]]; then
    return
  fi
  fail "indice-backend/src/main/resources/application-local.yaml est absent (ou les variables d'environnement ne sont pas définies). Consultez la section « Configuration » du README."
}

start_database() {
  info "Démarrage de la base PostgreSQL (Docker)"
  (cd "$BACKEND_DIR" && docker compose up -d)
}

backend_is_up() {
  curl --silent --fail --output /dev/null "$HEALTH_URL"
}

start_backend() {
  if lsof -ti tcp:8080 > /dev/null; then
    backend_is_up || fail "Le port 8080 est déjà utilisé par une autre application que l'API Indice."
    info "L'API est déjà lancée sur $API_URL : elle est réutilisée"
    return
  fi

  info "Démarrage de l'API (logs : logs/backend.log)"
  mkdir -p "$(dirname "$LOG_FILE")"
  (cd "$BACKEND_DIR" && ./mvnw spring-boot:run -Dspring-boot.run.profiles=local) > "$LOG_FILE" 2>&1 &
  BACKEND_PID=$!
  BACKEND_STARTED_BY_SCRIPT=true

  local waited=0
  until backend_is_up; do
    kill -0 "$BACKEND_PID" 2> /dev/null || fail "L'API s'est arrêtée au démarrage. Consultez logs/backend.log."
    (( waited >= STARTUP_TIMEOUT_SECONDS )) && fail "L'API ne répond pas après ${STARTUP_TIMEOUT_SECONDS} s. Consultez logs/backend.log."
    sleep 2
    waited=$(( waited + 2 ))
  done
  info "API prête sur $API_URL"
}

stop_backend() {
  [[ "$BACKEND_STARTED_BY_SCRIPT" == true ]] || return 0
  info "Arrêt de l'API"
  lsof -ti tcp:8080 | xargs kill 2> /dev/null || true
  kill "$BACKEND_PID" 2> /dev/null || true
}

prepare_mobile() {
  cd "$MOBILE_DIR"
  if [[ ! -f .env ]]; then
    info "Création de .env.local (simulateur iOS)"
    echo "API_BASE_URL=$API_URL" > .env
    echo "    Pour un émulateur Android, remplacez l'URL par http://10.0.2.2:8080/api dans indice_mobile/.env.local."
  fi

  info "Installation des dépendances Flutter"
  flutter pub get

  info "Génération du code (freezed, json_serializable)"
  dart run build_runner build --delete-conflicting-outputs
}

start_mobile() {
  info "Lancement de l'application mobile (q pour quitter)"
  flutter run "$@"
}

trap stop_backend EXIT

check_prerequisites
check_backend_config
start_database
start_backend
prepare_mobile
start_mobile "$@"
