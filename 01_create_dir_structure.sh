#!/bin/bash

# Função para gerar um nome de pasta sequencial caso nenhum seja fornecido
generate_folder_name() {
    prefix="CleanSeq_"
    count=1
    while [ -d "${prefix}$(printf '%02d' $count)" ]; do
        count=$((count + 1))
    done
    echo "${prefix}$(printf '%02d' $count)"
}

# Função para validar se o nome contém caracteres não permitidos
validate_folder_name() {
    if echo "$1" | grep -q '[^a-zA-Z0-9_-]'; then
        echo "Erro: O nome da pasta não pode conter caracteres especiais não suportados. Use apenas letras, números, underscore (_) ou hífen (-)."
        return 1
    elif echo "$1" | grep -q '[ ]'; then
        echo "Erro: O nome da pasta não pode conter espaços. Use apenas letras, números, underscore (_) ou hífen (-)."
        return 1
    else
        return 0
    fi
}

# Solicitar o nome da pasta inicial até que seja válido e não exista
while true; do
    read -p "Escreva o nome para a pasta inicial (ou deixe vazio para gerar automaticamente): " folder_name
    if [ -z "$folder_name" ]; then
        folder_name=$(generate_folder_name)
    fi

    if validate_folder_name "$folder_name"; then
        if [ -d "$folder_name" ]; then
            echo "A pasta $folder_name já existe. Por favor, escolha outro nome."
        else
            break
        fi
    fi
done

# Verificar e criar a estrutura de diretórios
echo "A criar a estrutura de diretórios em $folder_name..."
mkdir -p "$folder_name"/{01_rawdata_fastq,02_output_data/{03_fastqc_pre_trimmomatic,04_multiqc_pre_trimmomatic,05_trimmomatic_results,06_fastqc_post_trimmomatic,07_multiqc_post_trimmomatic}}
echo "Estrutura de diretórios criada com sucesso."

# Mover para o diretório de rawdata criado
echo "A mover para o diretório 01_rawdata..."
cd "$folder_name/01_rawdata_fastq" || exit

echo "Está agora na diretoria $folder_name/01_rawdata_fastq."