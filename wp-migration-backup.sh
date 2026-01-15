#!/bin/bash

# ========================================================================
# WordPress Migration Tool - Instalador Rápido
# Ejecutar con: curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash
# ========================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_message() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_header() {
    clear
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║     WordPress Migration Tool - Instalador Automático    ║"
    echo "║              All-in-One WP Migration Setup               ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Verificar si WP-CLI está instalado
check_wpcli() {
    if ! command -v wp &> /dev/null; then
        print_warning "WP-CLI no detectado. Instalando..."
        
        curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar 2>/dev/null
        chmod +x wp-cli.phar
        
        if [ -w "/usr/local/bin" ]; then
            mv wp-cli.phar /usr/local/bin/wp
            print_message "WP-CLI instalado en /usr/local/bin/wp"
        else
            sudo mv wp-cli.phar /usr/local/bin/wp 2>/dev/null || {
                mv wp-cli.phar ./wp
                print_warning "WP-CLI instalado localmente como ./wp"
            }
        fi
    else
        print_message "WP-CLI ya está instalado"
    fi
}

# Función principal
main() {
    print_header
    
    # Detectar si estamos ejecutando desde curl o localmente
    if [ -t 0 ]; then
        # Ejecución local (con terminal interactiva)
        INTERACTIVE=true
    else
        # Ejecución desde curl (sin interacción)
        INTERACTIVE=false
    fi
    
    print_message "Iniciando instalación..."
    echo ""
    
    # Verificar Git
    if ! command -v git &> /dev/null; then
        print_error "Git no está instalado. Por favor, instala Git primero."
        exit 1
    fi
    
    # Clonar repositorio
    print_message "Descargando WordPress Migration Tool..."
    
    if [ -d "wp-migration" ]; then
        print_warning "Directorio wp-migration ya existe. Eliminando..."
        rm -rf wp-migration
    fi
    
    if git clone https://github.com/systemblackpro/wp-migration.git 2>/dev/null; then
        print_message "Repositorio clonado exitosamente"
    else
        print_error "Error al clonar el repositorio"
        print_message "Intenta manualmente: git clone https://github.com/systemblackpro/wp-migration.git"
        exit 1
    fi
    
    cd wp-migration || {
        print_error "No se pudo acceder al directorio wp-migration"
        exit 1
    }
    
    # Dar permisos de ejecución
    chmod +x *.sh 2>/dev/null
    
    print_message "Scripts configurados correctamente"
    echo ""
    
    # Verificar WP-CLI
    check_wpcli
    echo ""
    
    # Mostrar información final
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              Instalación Completada ✓                    ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    print_message "Ubicación: $(pwd)"
    echo ""
    echo "📋 Archivos disponibles:"
    ls -1 *.sh 2>/dev/null | sed 's/^/   /'
    echo ""
    
    if [ "$INTERACTIVE" = true ]; then
        # Modo interactivo
        echo -e "${YELLOW}¿Qué deseas hacer ahora?${NC}"
        echo ""
        echo "1) Ejecutar el script de migración completo"
        echo "2) Solo instalar los plugins"
        echo "3) Salir (configurar manualmente después)"
        echo ""
        read -p "Selecciona una opción [1-3]: " choice
        
        case $choice in
            1)
                if [ -f "wp-migration-backup.sh" ]; then
                    echo ""
                    print_message "Ejecutando script de migración..."
                    echo ""
                    ./wp-migration-backup.sh
                else
                    print_error "Script wp-migration-backup.sh no encontrado"
                fi
                ;;
            2)
                if [ -f "install-plugins.sh" ]; then
                    ./install-plugins.sh
                else
                    print_warning "Script install-plugins.sh no encontrado"
                    print_message "Ejecuta manualmente: ./wp-migration-backup.sh"
                fi
                ;;
            3)
                print_message "Configuración guardada. Ejecuta cuando estés listo:"
                ;;
        esac
    else
        # Modo no interactivo (desde curl)
        print_warning "Ejecutado desde curl - modo no interactivo"
    fi
    
    echo ""
    echo -e "${GREEN}Próximos pasos:${NC}"
    echo ""
    echo "  cd wp-migration"
    echo "  ./wp-migration-backup.sh"
    echo ""
    echo -e "${BLUE}O ejecuta directamente:${NC}"
    echo ""
    echo "  cd wp-migration && ./wp-migration-backup.sh"
    echo ""
}

# Ejecutar
main
