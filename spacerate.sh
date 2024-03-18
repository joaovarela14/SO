#!/bin/bash

# Projeto realizado por: 
# *João Varela 113780
# *Carolina Prata 114246

declare cabecalho="SIZE NAME"
declare r_used=0    # Variável de controlo de uso da flag -r
declare a_used=0    # Variável de controlo de uso da flag -a
declare l_used=0    # Variável de controlo de uso da flag -l
declare diretorios_atuais=()   # Array que guarda os nomes dos ficheiros de output
declare -A dicionario
 

function menu(){  #menu de ajuda/explicção
    echo "-------------------------------------------------------------------------------------------------------"
    echo "Modo de utilização: ./spacerate.sh [opções] [filename][filename](obrigatório)"
    echo "Opções válidas:"
    echo "-r | --reverse : Ordena os ficheiros por ordem inversa."
    echo "-a | --alphabetic : Ordena por ordem alfabética(nomes)."
    echo "-l | --limit : Acompanhada pelo número de linhas a apresentar na tabela."
    echo "Os último argumentos: O último argumento passado tem de ser o nome dos ficheiros cujo conteúdo é o output de spacecheck."
    echo "-------------------------------------------------------------------------------------------------------"
}

function inputs(){
        if [[ $# -eq 0 ]]; then   #verifica se o número de argumentos é 0
            echo "Erro: Nenhum argumento passado."
            menu
            exit 1
        
        fi
    
        while getopts "ral:" opcao; do
            case $opcao in
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
                    numero=$OPTARG
                    if [ $l_used -eq 1 ]; then
                        echo "Erro: A flag -l foi usada mais de uma vez."
                        menu
                        exit 1
                    fi
    
                    l_used=1
                    
                    ;;

                *)
                    echo "Erro: Opção inválida."
                    menu
                    exit 1
                    
                    ;;
            esac
        done
    
        shift $((OPTIND -1))

        #verifica se o numero de argumentos é 2
        if [[ $# -ne 2 ]]; then
            echo "Erro: É necessário passar 2 ficheiros como argumento."
            menu
            exit 1
        fi

        for i in "$@"; do
            if [ ! -f "$i" ]; then
                echo "Erro: O ficheiro $i não existe."
                menu
                exit 1
            fi

        done        

        leitura_outputs $1 $2

}

function leitura_outputs() {
    file_recente="$1"
    file_antigo="$2"

    while read -r line; do
        if [[ $line == SIZE* ]]; then #verifica se a linha começa com SIZE
            continue
        fi

        tamanho=$(echo "$line" | awk '{print $1}') #guarda o tamanho do ficheiro
        diretorio=$(echo "$line" | awk '{print $2}') #guarda o nome do diretorio

        dicionario["$diretorio"]="$tamanho" #guarda no dicionario o nome do diretorio como key e o tamanho do ficheiro como value
        
    done < "$file_antigo"    #leitura do ficheiro mais antigo

    while read -r line; do
        if [[ $line == SIZE* ]] || [[ $line == ---* ]]; then
            continue
        fi

        tamanho=$(echo "$line" | awk '{print $1}')
        diretorio=$(echo "$line" | awk '{print $2}')
        diretorios_atuais+=("$diretorio")

        if [[ -v dicionario["$diretorio"] ]]; then
            
            tamanho_antigo="${dicionario[$diretorio]}" #tamanho do ficheiro no ficheiro mais antigo
            diferenca=$((tamanho - tamanho_antigo)) #diferença entre o tamanho do ficheiro no ficheiro mais recente e no mais antigo
            dicionario["$diretorio"]=$diferenca #atualiza no dicionario a diferença entre os tamanhos dos ficheiros

        else
            dicionario["$diretorio"]="$tamanho  NEW" #a diretoria não existe no ficheiro mais antigo logo é adicionada ao dicionario com NEW
        fi

    done < "$file_recente"


    while read -r line; do
        if [[ $line == SIZE* ]] || [[ $line == ---* ]]; then
            continue
        fi

        diretorio=$(echo "$line" | awk '{print $2}')
        tamanho=$(echo "$line" | awk '{print $1}')

        if [[ ! " ${diretorios_atuais[@]} " =~ " ${diretorio} " ]]; then
            dicionario["$diretorio"]="-$tamanho  REMOVED" #a diretoria não existe no ficheiro mais recente
            #logo é adicionada ao dicionario com REMOVED
        fi

    done < "$file_antigo" 

}

function print_dicionario(){
    local stop_for=${#dicionario[@]}

    if [ "$l_used" -eq 1 ]; then
        stop_for="$numero"
    fi

    if [ "$r_used" -eq 1 ] && [ "$a_used" -eq 0 ]; then
        for key in "${!dicionario[@]}"; do
            IFS=" " read -r tamanho status <<< "${dicionario[$key]}"
            printf "%-6s %s %s\n" "$tamanho" "$key" "$status"
        done | sort -n -k1 | head -n "$stop_for"
    
    elif [ "$a_used" -eq 1 ] && [ "$r_used" -eq 0 ]; then
        for key in "${!dicionario[@]}"; do
            IFS=" " read -r tamanho status <<< "${dicionario[$key]}"
            printf "%-6s %s %s\n" "$tamanho" "$key" "$status"
        done | sort -k2 | head -n "$stop_for"

    elif [ "$a_used" -eq 1 ] && [ "$r_used" -eq 1 ]; then
        for key in "${!dicionario[@]}"; do
            IFS=" " read -r tamanho status <<< "${dicionario[$key]}"
            printf "%-6s %s %s\n" "$tamanho" "$key" "$status"
        done | sort -r -k2 | head -n "$stop_for"

    else
        for key in "${!dicionario[@]}"; do
            IFS=" " read -r tamanho status <<< "${dicionario[$key]}"
            printf "%-6s %s %s\n" "$tamanho" "$key" "$status"
        done | sort -rn -k1 | head -n "$stop_for"
    fi

}


inputs "$@"
echo $cabecalho
print_dicionario
