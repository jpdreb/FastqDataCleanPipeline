#!/bin/bash

# Função para iniciar log
start_log() {
    log_file="fastqc_multiqc_post_log_$(date +%Y%m%d_%H%M%S).log"
    exec 3>&1 4>&2  # Guarda as saídas atuais (stdout e stderr)
    exec &> >(tee -a "$log_file")
    echo "Início da execução do script em $(date). Log será guardado em $log_file."
}

# Função para parar log
stop_log() {
    exec >&3 2>&4  # Restaura stdout e stderr para seus valores originais
    exec 3>&- 4>&-  # Fecha os descritores 3 e 4
    echo "Fim da execução do script em $(date)."
}

# Iniciar log
start_log

# Função para ativar o ambiente conda com validação
activate_conda_env() {
    while true; do
        read -p "Qual é o nome do ambiente conda que deseja ativar (com FastQC e MultiQC instalado)? " conda_env
        conda activate "$conda_env" &>/dev/null
        if [ $? -eq 0 ]; then
            echo "Ambiente $conda_env ativado com sucesso."
            break
        else
            echo "Erro: O ambiente $conda_env não existe ou não pode ser ativado. Tente novamente."
        fi
    done
}

# Função para correr o FastQC
run_fastqc() {
    input_dir="$1"
    output_dir="$2"
    echo "A correr FastQC em todos os ficheiros *_paired.fastq.gz em $input_dir..."
    for file in "$input_dir"/*_paired.fastq.gz; do
        fastqc -o "$output_dir" "$file"
    done
    echo "FastQC concluído. Resultados em $(realpath "$output_dir")."
}

# Função para correr o MultiQC
run_multiqc() {
    input_dir="$1"
    output_dir="$2"
    echo "A correr MultiQC nos resultados do FastQC..."
    multiqc -o "$output_dir" "$input_dir"
    echo "MultiQC concluído. Relatório em $(realpath "$output_dir")."
}

# Passo 1: Ativar ambiente conda
activate_conda_env

# Passo 2: Localizar pasta de dados processados pelo Trimmomatic
while true; do
    read -p "Qual é o nome da pasta criada para esta análise (ex: pasta antes de '01_rawdata_fastq')? " base_path
    processed_data_dir="$base_path/02_output_data/05_trimmomatic_results"
    if [ -d "$processed_data_dir" ]; then
        echo "A pasta $processed_data_dir foi encontrada."
        break
    else
        echo "Erro: A pasta $processed_data_dir não existe. Tente novamente."
    fi
done

# Verificar se os diretórios de saída já existem
fastqc_dir="$base_path/02_output_data/06_fastqc_post_trimmomatic"
multiqc_dir="$base_path/02_output_data/07_multiqc_post_trimmomatic"

if [ ! -d "$fastqc_dir" ] || [ ! -d "$multiqc_dir" ]; then
    echo "Erro: Um ou mais diretórios de saída necessários não existem."
    echo "Por favor, verifique os diretórios antes de executar o script novamente."
    stop_log
    return 0 2>/dev/null || exit 0
fi

# Passo 3: Analisar os dados com FastQC
run_fastqc "$processed_data_dir" "$fastqc_dir"

# Passo 4: Gerar relatório MultiQC
run_multiqc "$fastqc_dir" "$multiqc_dir"

# Gerar comando SCP para transferência do ficheiro multiqc_report.html
multiqc_report="$multiqc_dir/multiqc_report.html"
if [ -f "$multiqc_report" ]; then
    full_path=$(realpath "$multiqc_report")
    username="username" # Substitua pelo seu nome de utilizador
    servidor="servidor" # Substitua pelo nome ou IP do servidor
    echo "Para transferir o ficheiro para o seu computador, use o comando:"
    echo "scp $username@$servidor:$full_path ~/Downloads/"
else
    echo "Erro: O ficheiro multiqc_report.html não foi encontrado em $multiqc_report."
fi

# Passo 5: Desativar ambiente conda
conda deactivate
echo "O ambiente conda foi desativado."

# Parar log
stop_log