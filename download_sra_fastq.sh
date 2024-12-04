#!/bin/bash

# Diretório de saída para os ficheiros FASTQ
output_dir="fastq_downloads_$(date +%Y%m%d)"
index=1
while [ -d "${output_dir}_$index" ]; do
  ((index++))
done
output_dir="${output_dir}_$index"

echo "A criar o diretório de saída: $output_dir"
mkdir -p "$output_dir"
if [ $? -ne 0 ]; then
  echo "Erro ao criar o diretório de saída. A terminar o script."
  exit 1
fi

echo "Diretório de saída criado com sucesso."

# Lista de identificadores SRA
sra_ids=(
    "SRR10903401" # Substitua pelos IDs pretendidos
)

# Transferir e organizar os ficheiros FASTQ
for sra_id in "${sra_ids[@]}"; do
    echo "A transferir ficheiro para SRA ID: $sra_id"
    
    # Usar fasterq-dump para descarregar os dados FASTQ
    echo "A executar o comando: fasterq-dump $sra_id --split-files -O $output_dir"
    fasterq-dump "$sra_id" --split-files -O "$output_dir"
    if [ $? -ne 0 ]; then
      echo "Erro ao transferir o ficheiro para SRA ID: $sra_id. A terminar o script."
      exit 1
    fi
    
    echo "Transferência do ficheiro $sra_id concluída com sucesso."
    
    # Verificar e renomear ficheiros paired-end
    if [ -f "$output_dir/${sra_id}_1.fastq" ]; then
        echo "Ficheiro ${sra_id}_1.fastq encontrado. A renomear para ${sra_id}_1_aaa.fastq e a comprimir."
        mv "$output_dir/${sra_id}_1.fastq" "$output_dir/${sra_id}_1_aaa.fastq"
        if [ $? -eq 0 ]; then
            gzip "$output_dir/${sra_id}_1_aaa.fastq"
            if [ $? -ne 0 ]; then
                echo "Erro ao comprimir o ficheiro ${sra_id}_1_aaa.fastq. A terminar o script."
                exit 1
            fi
        else
            echo "Erro ao renomear o ficheiro ${sra_id}_1.fastq. A terminar o script."
            exit 1
        fi
    else
        echo "Ficheiro ${sra_id}_1.fastq não encontrado. A continuar para o próximo ficheiro."
    fi
    
    if [ -f "$output_dir/${sra_id}_2.fastq" ]; then
        echo "Ficheiro ${sra_id}_2.fastq encontrado. A renomear para ${sra_id}_2_aaa.fastq e a comprimir."
        mv "$output_dir/${sra_id}_2.fastq" "$output_dir/${sra_id}_2_aaa.fastq"
        if [ $? -eq 0 ]; then
            gzip "$output_dir/${sra_id}_2_aaa.fastq"
            if [ $? -ne 0 ]; then
                echo "Erro ao comprimir o ficheiro ${sra_id}_2_aaa.fastq. A terminar o script."
                exit 1
            fi
        else
            echo "Erro ao renomear o ficheiro ${sra_id}_2.fastq. A terminar o script."
            exit 1
        fi
    else
        echo "Ficheiro ${sra_id}_2.fastq não encontrado. A continuar para o próximo ficheiro."
    fi

done

echo "Transferências concluídas. Os ficheiros estão disponíveis em: $output_dir"