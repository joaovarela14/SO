#!/bin/bash

# Projeto realizado por: 
# *João Varela 113780
# *Carolina Prata 114246

declare cabecalho="SIZE NAME $(date +%Y%m%d) $@"   
declare n_used=0    # Variável de controlo de uso da flag -n
declare d_used=0    # Variável de controlo de uso da flag -d
declare s_used=0    # Variável de controlo de uso da flag -s
declare r_used=0    # Variável de controlo de uso da flag -r
declare a_used=0    # Variável de controlo de uso da flag -a
declare l_used=0    # Variável de controlo de uso da flag -l
declare i=0;        # Variável de controlo do array de diretórios e fors
declare diretorios=()       # Array de diretórios
declare nome=""     # Variável que guarda o nome do tipo de ficheiro a procurar
declare -A pastas_e_subpastas   # Dicionário que guarda o nome da pasta e o tamanho ocupado pelos ficheiros 
declare data=$(date -d "$data" +%s)   # Variável que guarda a data atual em segundos desde 1970
declare size=0      # Variável que guarda o tamanho mínimo do ficheiro a procurar


function menu(){  #menu de ajuda/explicção
    echo "-------------------------------------------------------------------------------------------------------"
    echo "Modo de utilização: ./spacecheck.sh [opções] [condição](opcional) [diretório](obrigatório)"
    echo "Opções válidas:"
    echo "-n | --name : Procura por ficheiros com o nome especificado."
    echo "-d | --date : Procura por ficheiros com a data de modificação anterior à data especificada."
    echo "-s | --size : Procura por ficheiros com o tamanho igual ou maior ao especificado."
    echo "-r | --reverse : Ordena os ficheiros por ordem inversa."
    echo "-a | --alphabetic : Ordena por ordem alfabética(nomes)."
    echo "-l | --limit : Acompanhada pelo número de linhas a apresentar na tabela."
    echo "Último argumento: O último argumento passado tem de ser o nome do diretório a procurar."
    echo "-------------------------------------------------------------------------------------------------------"
}


function inputs(){

    if [[ $# == 0 ]]; then   #verifica se o número de argumentos é 0
        echo "Erro: Nenhum argumento passado."
        menu
        exit 1
    fi

    while getopts "n:d:s:ral:" opcao; do
        case $opcao in
            n)
                nome="$OPTARG"
                if [ $n_used -eq 1 ]; then
                    echo "Erro: A flag -n foi usada mais de uma vez."
                    menu
                    exit 1
                fi

                n_used=1

                ;;

            d)
                data="$OPTARG"
                data=$(date -d "$data" +%s 2>/dev/null)
                # Verificar se a data é válida
                if [ $? -ne 0 ]; then
                    echo "Erro: A data inserida não é válida."
                    menu
                    exit 1
                fi
                
                if [ $d_used -eq 1 ]; then
                    echo "Erro: A flag -d foi usada mais de uma vez."
                    menu
                    exit 1
                fi
                
                d_used=1
                ;;
            
            s)
                size="$OPTARG"
                if [ $s_used -eq 1 ]; then
                    echo "Erro: A flag -s foi usada mais de uma vez."
                    menu
                    exit 1
                fi 

                # Verificar se o tamanho é válido (maior que 0)
                if [ "$size" -le 0 ]; then
                    echo "Erro: O tamanho do ficheiro tem de ser maior que 0."
                    menu
                    exit 1
                fi

                s_used=1
                ;;

            r)
                if [ $r_used -eq 1 ]; then
                    echo "Erro: A flag -r foi usada mais de uma vez."
                    menu
                    exit 1
                fi
                r_used=1
                ;;

            a) 
                if [ $a_used -eq 1 ]; then
                    echo "Erro: A flag -a foi usada mais de uma vez."
                    menu
                    exit 1
                fi
                a_used=1
                ;;

            l)
                numero="$OPTARG"
                if [ $l_used -eq 1 ]; then
                    echo "Erro: A flag -l foi usada mais de uma vez."
                    menu
                    exit 1
                fi

                # Verificar se o número de linhas é válido (maior que 0)
                if [ "$numero" -le 0 ]; then
                    echo "Erro: O número de linhas a apresentar tem de ser maior que 0."
                    menu
                    exit 1
                fi

                l_used=1
                ;;

        esac
    done

    shift $((OPTIND -1))  # Ignorar os argumentos já lidos

    if [ $# -eq 0 ]; then   #verifica se o número de argumentos é 0
        echo "Erro: Nenhum diretório passado." 
        menu
        exit 1
    fi

    for dir in "$@"; do  
        if [ -d "$dir" ]; then      #verifica se o argumento é um diretório
            diretorios[$i]="$dir"  #adiciona o diretório ao array
            i=$((i+1))
        else
            echo "Erro: O argumento '$dir' não é um diretório."  
            menu 
            exit 1
        fi
    done

}

function encontrar_ficheiros() {
    local pasta_main="$1"    

    if [ "$nome" != "" ]; then
        tipo_ficheiro="$nome"
    else
        tipo_ficheiro="*"
    fi
    
    calcular_tamanho_total() {
        local pasta="$1"
        local tamanho_total=0


        if [ ! -r "$1" ]; then
            tamanho_total=-1

        else
            while read -r ficheiro; do
                data_modificacao=$(stat -c "%y" "$ficheiro")
                data_modificacao_segundos=$(date -d "$data_modificacao" +%s)
                tamanho_ficheiro=$(stat -c %s "$ficheiro")
                if [ "$data_modificacao_segundos" -le "$data" ] && [ "$tamanho_ficheiro" -gt "$size" ]; then
                    
                    tamanho_total=$((tamanho_total + tamanho_ficheiro))
                fi

            done < <(find "$pasta" -type f -name "$tipo_ficheiro" 2>/dev/null)

        fi
        echo "$tamanho_total"
    }

    # Usar o comando 'find' para listar todas as pastas dentro da pasta principal
    while IFS= read -r -d $'\0' pasta; do
        tamanho_pasta=$(calcular_tamanho_total "$pasta")
        
        if [ "$tamanho_pasta" -eq -1 ]; then        # Verificar se a pasta é legível
            tamanho_pasta="NA"
        fi
        pastas_e_subpastas["$pasta"]=$tamanho_pasta   # Adicionar ao dicionário o nome da pasta e o tamanho total dos ficheiros

    done < <(find "$pasta_main" -type d -print0 2>/dev/null )

}

function print_dicionario(){
    local stop_for=${#pastas_e_subpastas[@]}

    if [ "$l_used" -eq 1 ]; then
        stop_for="$numero"
    fi

    if [ "$r_used" -eq 1 ] && [ "$a_used" -eq 0 ]; then
        for key in "${!pastas_e_subpastas[@]}"; do
            printf "%-6s %s\n" "${pastas_e_subpastas[$key]}" "$key"
        done | sort -n -k1 | head -n "$stop_for"
    
    elif [ "$a_used" -eq 1 ] && [ "$r_used" -eq 0 ]; then
        for key in "${!pastas_e_subpastas[@]}"; do
            printf "%-6s %s\n" "${pastas_e_subpastas[$key]}" "$key"
        done | sort -k2 | head -n "$stop_for"

    elif [ "$a_used" -eq 1 ] && [ "$r_used" -eq 1 ]; then
        for key in "${!pastas_e_subpastas[@]}"; do
            printf "%-6s %s\n" "${pastas_e_subpastas[$key]}" "$key"
        done | sort -r -k2 | head -n "$stop_for"

    else
        for key in "${!pastas_e_subpastas[@]}"; do
            printf "%-6s %s\n" "${pastas_e_subpastas[$key]}" "$key"
        done | sort -rn -k1 | head -n "$stop_for"
    fi
    printf "\n"

}


main() {
    inputs "$@"
    echo $cabecalho

    for dir in "${diretorios[@]}"; do
        encontrar_ficheiros "$dir"
    done
    print_dicionario
    
}

main "$@"