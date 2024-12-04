# FastqDataCleanPipeline

## Descrição do Workflow
Este repositório contém scripts que permitem a criação e execução de um workflow para limpeza e análise de ficheiros de sequências FASTQ. O workflow é composto por quatro scripts principais, e um opcional, descritos abaixo, que facilitam a execução de vários passos, desde a organização inicial dos dados à análise pós-processamento. Todos os scripts foram criados para serem utilizados no contexto de bioinformática e biologia computacional.

## Requisitos de Instalação
Para correr o pipeline, é necessário utilizar um ambiente Conda com as seguintes ferramentas instaladas:

1. **Miniconda3** – pode ser utilizado para gerir o ambiente Conda.
2. **Criação do Ambiente Conda para QC:**
   ```bash
   conda create -n tools_qc
   conda activate tools_qc
   conda install -c bioconda fastqc
   conda install -c bioconda multiqc
   conda install -c bioconda trimmomatic
   ```
3. **Script opcional para Download de Dados SRA**:
   
   Para correr o script `download_sra_fastq.sh`, crie e ative o ambiente com o seguinte comando:
   ```bash
   conda create -n sra_tools_env sra-tools -y
   conda activate sra_tools_env
   ```

## Descrição dos Scripts

### 1. `01_create_dir_structure.sh`
Este script cria a estrutura inicial de diretórios necessária para o pipeline de análise. Ele solicita ao utilizador um nome para o diretório principal e cria subdiretórios que irão conter os dados brutos, resultados do FastQC, MultiQC, Trimmomatic e outros outputs subsequentes. Para utilizá-lo, execute o comando:

```bash
source 01_create_dir_structure.sh
```

Após a criação da estrutura de diretórios, copie os ficheiros comprimidos `.fastq.gz` para a pasta `01_rawdata_fastq` gerada.

### 2. `02_fastqc_multiqc_pre.sh`
Este script faz a análise da qualidade dos ficheiros FASTQ brutos usando **FastQC** e **MultiQC** antes da limpeza com Trimmomatic. O script ativa o ambiente Conda especificado pelo utilizador, verifica a presença dos diretórios de saída necessários e analisa os ficheiros com FastQC, gerando um relatório consolidado com MultiQC.

Para executar este script:
```bash
source 02_fastqc_multiqc_pre.sh
```
**Nota:** Este script gera um ficheiro de log na diretória corrente com o nome e a data da execução.

### 3. `03_trimmomatic.sh`
Este script permite correr o **Trimmomatic** para a limpeza dos ficheiros FASTQ, removendo adaptadores e bases de baixa qualidade. Durante a execução, é solicitado ao utilizador o ambiente Conda a ser ativado, o ficheiro de adaptadores a utilizar e se os dados são **paired-end** ou **single-end**. Posteriormente, o script executa o Trimmomatic nos ficheiros brutos e armazena os resultados na pasta `02_output_data/05_trimmomatic_results`.

Para executar este script:
```bash
source 03_trimmomatic.sh
```

### 4. `04_fastqc_multiqc_post.sh`
Este script realiza a análise da qualidade dos ficheiros após o processo de limpeza com **Trimmomatic** usando **FastQC** e **MultiQC**. Ele segue um processo semelhante ao script `02_fastqc_multiqc_pre.sh`, mas aplicado aos ficheiros que passaram pelo Trimmomatic. Os resultados gerados encontram-se na pasta `02_output_data/07_multiqc_post_trimmomatic`.

Para executar este script:
```bash
source 04_fastqc_multiqc_post.sh
```

### 5. `download_sra_fastq.sh` (Opcional)
Este script opcional permite o download de dados do **NCBI SRA** (Sequence Read Archive) utilizando o **fasterq-dump**. Os ficheiros descarregados são automaticamente renomeados e comprimidos. É uma boa opção para quem não possui dados FASTQ próprios para testar o pipeline.

Para executar este script:
```bash
source download_sra_fastq.sh
```

## Observações Importantes

- **Formatos dos Ficheiros**: Os ficheiros `.fastq.gz` podem ser **paired-end** ou **single-end**. Caso sejam paired-end, é recomendado que estejam nomeados num formato consistente, como `*_1.fastq.gz` e `*_2.fastq.gz`.
- **Ficheiros Comprimidos**: Todos os ficheiros `.fastq` devem estar comprimidos no formato `.gz`. No entanto, é possível alterar os scripts para trabalhar diretamente com ficheiros `.fastq` não comprimidos, substituindo as ocorrências de `*.fastq.gz` por `*.fastq`.
- **Transferência de Relatórios**: Após a geração dos relatórios MultiQC, é possível transferi-los do servidor para o computador local usando comandos como `scp`. As instruções para isso são apresentadas pelo script durante a execução.
- **Verificação da Instalação**: Opcionalmente, pode-se executar comandos para verificar se o software **FastQC**, **MultiQC**, **Trimmomatic** e **sra-tools** estão devidamente instalados.

## Como Começar
1. **Clone este repositório**:
   ```bash
   git clone <URL_DO_REPOSITORIO>
   cd FastqDataCleanPipeline
   ```
2. **Execute o script de criação de diretórios** (`01_create_dir_structure.sh`).
3. **Mova os ficheiros FASTQ comprimidos** para a pasta `01_rawdata_fastq`.
4. **Siga a sequência de scripts**, garantindo que estão a ser usados os ambientes Conda adequados.