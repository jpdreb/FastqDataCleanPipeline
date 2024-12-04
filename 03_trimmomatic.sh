#!/bin/bash

# Função para iniciar log
start_log() {
    log_file="trimmomatic_log_$(date +%Y%m%d_%H%M%S).log"
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

# Função para ativar o ambiente conda
activate_conda_env() {
    while true; do
        read -p "Qual é o nome do ambiente conda que deseja ativar (com Trimmomatic instalado)? " conda_env
        conda activate "$conda_env" &>/dev/null
        if [ $? -eq 0 ]; then
            echo "Ambiente $conda_env ativado com sucesso."
            break
        else
            echo "Erro: O ambiente $conda_env não existe ou não pode ser ativado. Tente novamente."
        fi
    done
}

# Função para localizar e validar a pasta de dados brutos
locate_raw_data() {
    while true; do
        read -p "Qual é o nome da pasta criada para esta análise (ex: pasta antes de '01_rawdata_fastq')? " base_path
        rawdata_dir="$base_path/01_rawdata_fastq"
        if [ -d "$rawdata_dir" ]; then
            echo "Pasta $rawdata_dir encontrada."
            break
        else
            echo "Erro: A pasta $rawdata_dir não existe. Tente novamente."
        fi
    done
}

# Função para configurar os adaptadores
set_adapters() {
    while true; do
        read -p "Especifique o nome do ficheiro de adaptadores (ex.: TruSeq3-PE.fa): " adapter_file
        adapter_path="/home/$(whoami)/miniconda3/envs/$conda_env/share/trimmomatic-0.39-2/adapters/$adapter_file"
        if [ -f "$adapter_path" ]; then
            echo "Adaptador configurado: $adapter_path."
            break
        else
            echo "Erro: O adaptador $adapter_file não foi encontrado em $adapter_path. Tente novamente."
        fi
    done
}

# Função para definir se os dados são paired-end ou single-end
define_data_type() {
    while true; do
        read -p "Os seus dados são paired-end (digite 'paired') ou single-end (digite 'single')? " data_type
        case $data_type in
            paired|PAIRED)
                paired_end="true"
                echo "Definido: Dados paired-end."
                read -p "Qual é o padrão dos ficheiros R1? (ex.: *_R1.fastq.gz, *_1.fastq.gz): " pattern_r1
                read -p "Qual é o padrão dos ficheiros R2? (ex.: *_R2.fastq.gz, *_2.fastq.gz): " pattern_r2
                pattern_r1="${pattern_r1//\*/}" # Remove o asterisco para evitar duplicidade
                pattern_r2="${pattern_r2//\*/}" # Remove o asterisco para evitar duplicidade
                ;;
            single|SINGLE)
                paired_end="false"
                echo "Definido: Dados single-end."
                ;;
            *)
                echo "Resposta inválida. Por favor, digite 'paired' ou 'single'."
                ;;
        esac
        if [[ "$data_type" == "paired" || "$data_type" == "single" ]]; then
            break
        fi
    done
}

# Função para configurar parâmetros do Trimmomatic
set_trimmomatic_params() {
    echo "Configure os parâmetros do Trimmomatic (deixe em branco para não usar esse parâmetro)."
    read -p "ILLUMINACLIP (ex.: 2:30:10): " illuminaclip
    read -p "SLIDINGWINDOW (ex.: 4:20): " slidingwindow
    read -p "MINLEN (ex.: 36): " minlen
    read -p "LEADING (ex.: 3): " leading
    read -p "TRAILING (ex.: 3): " trailing
    read -p "CROP (ex.: 100): " crop
    read -p "HEADCROP (ex.: 10): " headcrop
    read -p "MAXINFO (ex.: 40:0.5): " maxinfo
    read -p "AVGQUAL (ex.: 20): " avgqual
    while true; do
        read -p "TOPHRED (33 ou 64, deixe em branco para ser determinado automaticamente): " tophred
        if [[ -z "$tophred" || "$tophred" == "33" || "$tophred" == "64" ]]; then
            break
        else
            echo "Resposta inválida. Por favor, digite '33', '64' ou deixe em branco para ser determinado automaticamente."
        fi
    done

    echo "Parâmetros configurados: ILLUMINACLIP=$illuminaclip, SLIDINGWINDOW=$slidingwindow, MINLEN=$minlen, LEADING=$leading, TRAILING=$trailing, CROP=$crop, HEADCROP=$headcrop, MAXINFO=$maxinfo, AVGQUAL=$avgqual, TOPHRED=${tophred:-auto}."
}

# Função para processar ficheiros com Trimmomatic
run_trimmomatic() {
    output_dir="$base_path/02_output_data/05_trimmomatic_results"
    if [ ! -d "$output_dir" ]; then
        echo "Erro: A pasta $output_dir não existe. Certifique-se de que foi criada corretamente pelo script create_dir_structure.sh."
        exit 1
    fi

    echo "A processar ficheiros com Trimmomatic..."

    if [ "$paired_end" = "true" ]; then
        for file in "$rawdata_dir"/*$pattern_r1; do
            base=$(basename "$file" "$pattern_r1")
            trimmomatic PE ${tophred:+-phred$tophred} \
                "$rawdata_dir/${base}${pattern_r1}" "$rawdata_dir/${base}${pattern_r2}" \
                "$output_dir/${base}_R1_paired.fastq.gz" "$output_dir/${base}_R1_unpaired.fastq.gz" \
                "$output_dir/${base}_R2_paired.fastq.gz" "$output_dir/${base}_R2_unpaired.fastq.gz" \
                ${illuminaclip:+ILLUMINACLIP:"$adapter_path":$illuminaclip} ${slidingwindow:+SLIDINGWINDOW:$slidingwindow} ${minlen:+MINLEN:$minlen} ${leading:+LEADING:$leading} ${trailing:+TRAILING:$trailing} ${crop:+CROP:$crop} ${headcrop:+HEADCROP:$headcrop} ${maxinfo:+MAXINFO:$maxinfo} ${avgqual:+AVGQUAL:$avgqual}
        done
    else
        for file in "$rawdata_dir"/*.fastq.gz; do
            base=$(basename "$file" ".fastq.gz")
            trimmomatic SE ${tophred:+-phred$tophred} \
                "$file" \
                "$output_dir/${base}_trimmed.fastq.gz" \
                ILLUMINACLIP:"$adapter_path":$illuminaclip SLIDINGWINDOW:$slidingwindow MINLEN:$minlen LEADING:$leading TRAILING:$trailing ${crop:+CROP:$crop} ${headcrop:+HEADCROP:$headcrop} ${maxinfo:+MAXINFO:$maxinfo} ${avgqual:+AVGQUAL:$avgqual}
        done
    fi

    echo "Processamento do Trimmomatic concluído. Resultados em $(realpath "$output_dir")."
}

# Passo 1: Ativar ambiente conda
activate_conda_env

# Passo 2: Localizar pasta de dados brutos
locate_raw_data

# Passo 3: Configurar adaptadores
set_adapters

# Passo 4: Definir o tipo de dados
define_data_type

# Passo 5: Configurar parâmetros do Trimmomatic
set_trimmomatic_params

# Passo 6: Processar com Trimmomatic
run_trimmomatic

# Passo 7: Desativar ambiente conda
conda deactivate
echo "O ambiente conda foi desativado."

# Parar log
stop_log