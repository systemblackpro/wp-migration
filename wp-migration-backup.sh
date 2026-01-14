#!/bin/bash

# Colores para mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color

# Función para mostrar mensajes
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"
}

# Verificar si WP-CLI está instalado
if ! command -v wp &> /dev/null; then
    print_error "WP-CLI no está instalado. Por favor, instálalo primero."
    exit 1
fi

# Directorio de trabajo (cambia esto si es necesario)
CURRENT_PATH="$(pwd)"

echo perms "$CURRENT_PATH"
WP_PATH="$CURRENT_PATH"

# Verificar si el directorio de WordPress existe
if [ ! -d "$WP_PATH" ]; then
    print_error "El directorio de WordPress no existe: $WP_PATH"
    exit 1
fi

cd "$WP_PATH" || exit 1

print_message "=== Instalación de Plugins All-in-One WP Migration ==="

# Verificar si los archivos .zip existen
if [ ! -f "all-in-one-wp-migration.zip" ]; then
    print_error "No se encuentra el archivo all-in-one-wp-migration.zip en $WP_PATH"
    exit 1
fi

if [ ! -f "all-in-one-wp-migration-unlimited-extension.zip" ]; then
    print_error "No se encuentra el archivo all-in-one-wp-migration-unlimited-extension.zip en $WP_PATH"
    exit 1
fi

# Instalar y activar All-in-One WP Migration
print_message "Instalando All-in-One WP Migration..."
if wp plugin install all-in-one-wp-migration.zip --activate --allow-root; then
    print_message "✓ All-in-One WP Migration instalado y activado correctamente"
else
    print_error "Error al instalar All-in-One WP Migration"
    exit 1
fi

# Instalar y activar la extensión Unlimited
print_message "Instalando All-in-One WP Migration Unlimited Extension..."
if wp plugin install all-in-one-wp-migration-unlimited-extension.zip --activate --allow-root; then
    print_message "✓ Unlimited Extension instalada y activada correctamente"
else
    print_error "Error al instalar Unlimited Extension"
    exit 1
fi

print_message "=== Plugins instalados exitosamente ==="
echo ""

# Menú de opciones para backup
while true; do
    echo ""
    echo "=== OPCIONES DE BACKUP ==="
    echo "1) Crear backup completo"
    echo "2) Crear backup de base de datos solamente"
    echo "3) Crear backup de archivos solamente"
    echo "4) Listar backups existentes"
    echo "5) Exportar backup a archivo"
    echo "6) Salir"
    echo ""
    read -p "Selecciona una opción [1-6]: " option

    case $option in
        1)
            print_message "Creando backup completo..."
            BACKUP_NAME="backup-completo-$(date +%Y%m%d-%H%M%S).wpress"
            
            # Crear directorio de backups si no existe
            mkdir -p "$WP_PATH/wp-content/ai1wm-backups"
            
            # Exportar backup completo
            wp ai1wm backup --allow-root
            
            if [ $? -eq 0 ]; then
                print_message "✓ Backup completo creado exitosamente"
                print_message "Ubicación: $WP_PATH/wp-content/ai1wm-backups/"
            else
                print_error "Error al crear el backup"
            fi
            ;;
        
        2)
            print_message "Creando backup de base de datos..."
            wp db export "$WP_PATH/backup-db-$(date +%Y%m%d-%H%M%S).sql" --allow-root
            
            if [ $? -eq 0 ]; then
                print_message "✓ Backup de base de datos creado"
            else
                print_error "Error al crear backup de base de datos"
            fi
            ;;
        
        3)
            print_message "Creando backup de archivos..."
            BACKUP_DIR="$WP_PATH/backups-archivos"
            mkdir -p "$BACKUP_DIR"
            BACKUP_FILE="$BACKUP_DIR/archivos-$(date +%Y%m%d-%H%M%S).tar.gz"
            
            tar -czf "$BACKUP_FILE" --exclude="$BACKUP_DIR" -C "$WP_PATH" .
            
            if [ $? -eq 0 ]; then
                print_message "✓ Backup de archivos creado: $BACKUP_FILE"
            else
                print_error "Error al crear backup de archivos"
            fi
            ;;
        
        4)
            print_message "Listando backups existentes..."
            echo ""
            echo "--- Backups de All-in-One WP Migration ---"
            if [ -d "/wp-content/ai1wm-backups" ]; then
                ls -lh "/wp-content/ai1wm-backups/"
            else
                print_warning "No se encontraron backups de All-in-One WP Migration"
            fi
            
            echo ""
            echo "--- Backups de base de datos ---"
            ls -lh "$WP_PATH"/backup-db-*.sql 2>/dev/null || print_warning "No se encontraron backups de base de datos"
            
            echo ""
            echo "--- Backups de archivos ---"
            if [ -d "$WP_PATH/backups-archivos" ]; then
                ls -lh "$WP_PATH/backups-archivos/"
            else
                print_warning "No se encontraron backups de archivos"
            fi
            ;;
        
        5)
            print_message "Exportando backup usando All-in-One WP Migration..."
            read -p "¿Incluir base de datos? (s/n): " include_db
            read -p "¿Incluir archivos multimedia? (s/n): " include_media
            read -p "¿Incluir temas? (s/n): " include_themes
            read -p "¿Incluir plugins? (s/n): " include_plugins
            
            EXPORT_OPTS=""
            [[ "$include_db" == "n" ]] && EXPORT_OPTS="$EXPORT_OPTS --exclude-database"
            [[ "$include_media" == "n" ]] && EXPORT_OPTS="$EXPORT_OPTS --exclude-media"
            [[ "$include_themes" == "n" ]] && EXPORT_OPTS="$EXPORT_OPTS --exclude-themes"
            [[ "$include_plugins" == "n" ]] && EXPORT_OPTS="$EXPORT_OPTS --exclude-plugins"
            
            wp ai1wm backup $EXPORT_OPTS --allow-root
            
            if [ $? -eq 0 ]; then
                print_message "✓ Exportación completada"
            else
                print_error "Error durante la exportación"
            fi
            ;;
        
        6)
            print_message "Saliendo..."
            cd ..
            rm -f wp-migration
            
            exit 0
            ;;
        
        *)
            print_error "Opción inválida. Por favor, selecciona una opción del 1 al 6."
            ;;
    esac
done
