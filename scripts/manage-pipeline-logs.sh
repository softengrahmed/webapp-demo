#!/bin/bash

# Pipeline Log Management Script
# Purpose: Manage, analyze, and archive pipeline logs
# Generated: 2025-08-10 14:30:45

set -e

# Configuration
LOG_BRANCH="deployment-reports"
LOG_BASE_PATH="deployment-reports"
ARCHIVE_PATH="${LOG_BASE_PATH}/archive"
RETENTION_DAYS_DEV=7
RETENTION_DAYS_STAGING=14
RETENTION_DAYS_PROD=30
CURRENT_DATE=$(date +"%Y-%m-%d")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}    CI/CD Pipeline Log Management Tool${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
}

print_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  view [RUN_ID]        View logs for a specific run"
    echo "  list [DATE]          List all logs for a date (YYYY-MM-DD)"
    echo "  search [PATTERN]     Search logs for a pattern"
    echo "  analyze              Analyze pipeline metrics"
    echo "  cleanup              Clean old logs based on retention"
    echo "  archive [DATE]       Archive logs for a specific month"
    echo "  export [RUN_ID]      Export logs to various formats"
    echo "  monitor              Real-time pipeline monitoring"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -b, --branch        Specify log branch (default: deployment-reports)"
    echo "  -v, --verbose       Verbose output"
    echo ""
}

check_prerequisites() {
    if ! command -v git &> /dev/null; then
        echo -e "${RED}Error: git is not installed${NC}"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}Warning: jq is not installed (some features may not work)${NC}"
    fi
}

fetch_log_branch() {
    echo -e "${BLUE}Fetching log branch...${NC}"
    git fetch origin ${LOG_BRANCH}:${LOG_BRANCH} 2>/dev/null || {
        echo -e "${YELLOW}Log branch not found. Creating...${NC}"
        git checkout -b ${LOG_BRANCH}
        return
    }
    git checkout ${LOG_BRANCH} 2>/dev/null
}

view_logs() {
    local RUN_ID=$1
    
    if [ -z "$RUN_ID" ]; then
        echo -e "${RED}Error: Please provide a RUN_ID${NC}"
        echo "Usage: $0 view [RUN_ID]"
        exit 1
    fi
    
    fetch_log_branch
    
    # Find log file
    local LOG_FILE=$(find ${LOG_BASE_PATH} -name "pipeline-logs.md" -path "*/run-${RUN_ID}/*" 2>/dev/null | head -1)
    
    if [ -z "$LOG_FILE" ]; then
        echo -e "${RED}Error: No logs found for run ${RUN_ID}${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Found logs: ${LOG_FILE}${NC}"
    echo ""
    
    # Display logs with syntax highlighting if available
    if command -v bat &> /dev/null; then
        bat --style=full --paging=always "$LOG_FILE"
    elif command -v less &> /dev/null; then
        less "$LOG_FILE"
    else
        cat "$LOG_FILE"
    fi
}

list_logs() {
    local DATE=$1
    
    if [ -z "$DATE" ]; then
        DATE=$CURRENT_DATE
    fi
    
    fetch_log_branch
    
    echo -e "${BLUE}Pipeline runs for ${DATE}:${NC}"
    echo ""
    
    if [ -d "${LOG_BASE_PATH}/${DATE}" ]; then
        for run_dir in ${LOG_BASE_PATH}/${DATE}/run-*/; do
            if [ -d "$run_dir" ]; then
                RUN_ID=$(basename "$run_dir")
                LOG_FILE="${run_dir}pipeline-logs.md"
                
                if [ -f "$LOG_FILE" ]; then
                    # Extract summary info
                    STATUS=$(grep "Pipeline Result:" "$LOG_FILE" 2>/dev/null | head -1 | cut -d':' -f2 | xargs)
                    BRANCH=$(grep "Branch:" "$LOG_FILE" 2>/dev/null | head -1 | cut -d':' -f2 | xargs)
                    DURATION=$(grep "Total Duration:" "$LOG_FILE" 2>/dev/null | head -1 | cut -d':' -f2 | xargs)
                    
                    echo -e "  ${GREEN}●${NC} ${RUN_ID}"
                    echo "    Status: ${STATUS:-UNKNOWN}"
                    echo "    Branch: ${BRANCH:-unknown}"
                    echo "    Duration: ${DURATION:-unknown}"
                    echo ""
                fi
            fi
        done
    else
        echo -e "${YELLOW}No logs found for ${DATE}${NC}"
    fi
}

search_logs() {
    local PATTERN=$1
    
    if [ -z "$PATTERN" ]; then
        echo -e "${RED}Error: Please provide a search pattern${NC}"
        echo "Usage: $0 search [PATTERN]"
        exit 1
    fi
    
    fetch_log_branch
    
    echo -e "${BLUE}Searching for '${PATTERN}' in all logs...${NC}"
    echo ""
    
    # Search with context
    grep -r "$PATTERN" ${LOG_BASE_PATH} --include="*.md" -n -C 2 2>/dev/null | while IFS=: read -r file line content; do
        # Format output
        if [[ "$file" != "--" ]]; then
            echo -e "${GREEN}File:${NC} $file"
            echo -e "${YELLOW}Line $line:${NC} $content"
        else
            echo "$content"
        fi
    done
    
    # Count matches
    MATCH_COUNT=$(grep -r "$PATTERN" ${LOG_BASE_PATH} --include="*.md" 2>/dev/null | wc -l)
    echo ""
    echo -e "${BLUE}Found ${MATCH_COUNT} matches${NC}"
}

analyze_metrics() {
    fetch_log_branch
    
    echo -e "${BLUE}Analyzing Pipeline Metrics...${NC}"
    echo ""
    
    # Count total runs
    TOTAL_RUNS=$(find ${LOG_BASE_PATH} -name "pipeline-logs.md" 2>/dev/null | wc -l)
    echo "Total Pipeline Runs: ${TOTAL_RUNS}"
    
    # Count by status
    SUCCESS_COUNT=$(grep -r "Pipeline Result:.*SUCCESS" ${LOG_BASE_PATH} --include="*.md" 2>/dev/null | wc -l)
    FAILED_COUNT=$(grep -r "Pipeline Result:.*FAILED" ${LOG_BASE_PATH} --include="*.md" 2>/dev/null | wc -l)
    
    echo "Successful Runs: ${SUCCESS_COUNT}"
    echo "Failed Runs: ${FAILED_COUNT}"
    
    if [ $TOTAL_RUNS -gt 0 ]; then
        SUCCESS_RATE=$((SUCCESS_COUNT * 100 / TOTAL_RUNS))
        echo "Success Rate: ${SUCCESS_RATE}%"
    fi
    
    echo ""
    echo -e "${BLUE}Stage Statistics:${NC}"
    
    # Analyze stage failures
    for stage in "Build" "Security" "Quality" "Deploy" "Verify" "Cleanup"; do
        STAGE_SUCCESS=$(grep -r "${stage}.*success" ${LOG_BASE_PATH} --include="*.md" 2>/dev/null | wc -l)
        STAGE_FAILED=$(grep -r "${stage}.*failed" ${LOG_BASE_PATH} --include="*.md" 2>/dev/null | wc -l)
        echo "  ${stage}: ${STAGE_SUCCESS} success, ${STAGE_FAILED} failed"
    done
    
    echo ""
    echo -e "${BLUE}Recent Deployments:${NC}"
    
    # List recent deployments
    grep -r "Deployment URL:" ${LOG_BASE_PATH} --include="*.md" 2>/dev/null | tail -5 | while IFS=: read -r file rest; do
        echo "  - $rest"
    done
    
    echo ""
    echo -e "${BLUE}Cost Analysis:${NC}"
    
    # Extract cost estimates
    grep -r "Total Estimated:" ${LOG_BASE_PATH} --include="*.md" 2>/dev/null | tail -1 | cut -d':' -f3
}

cleanup_old_logs() {
    fetch_log_branch
    
    echo -e "${BLUE}Cleaning up old logs...${NC}"
    echo ""
    
    # Calculate cutoff dates
    CUTOFF_DEV=$(date -d "${RETENTION_DAYS_DEV} days ago" +%Y-%m-%d)
    CUTOFF_STAGING=$(date -d "${RETENTION_DAYS_STAGING} days ago" +%Y-%m-%d)
    CUTOFF_PROD=$(date -d "${RETENTION_DAYS_PROD} days ago" +%Y-%m-%d)
    
    echo "Retention Policy:"
    echo "  Dev: ${RETENTION_DAYS_DEV} days (cutoff: ${CUTOFF_DEV})"
    echo "  Staging: ${RETENTION_DAYS_STAGING} days (cutoff: ${CUTOFF_STAGING})"
    echo "  Prod: ${RETENTION_DAYS_PROD} days (cutoff: ${CUTOFF_PROD})"
    echo ""
    
    # Find and remove old logs
    for date_dir in ${LOG_BASE_PATH}/????-??-??/; do
        if [ -d "$date_dir" ]; then
            DIR_DATE=$(basename "$date_dir")
            
            # Determine environment from logs
            if grep -q "Environment:.*dev" "${date_dir}"*/pipeline-logs.md 2>/dev/null; then
                ENV="dev"
                CUTOFF=$CUTOFF_DEV
            elif grep -q "Environment:.*staging" "${date_dir}"*/pipeline-logs.md 2>/dev/null; then
                ENV="staging"
                CUTOFF=$CUTOFF_STAGING
            else
                ENV="prod"
                CUTOFF=$CUTOFF_PROD
            fi
            
            # Check if directory is older than cutoff
            if [[ "$DIR_DATE" < "$CUTOFF" ]]; then
                echo -e "${YELLOW}Removing old ${ENV} logs: ${DIR_DATE}${NC}"
                rm -rf "$date_dir"
            fi
        fi
    done
    
    echo -e "${GREEN}Cleanup completed${NC}"
    
    # Commit changes
    git add -A
    git commit -m "Automated cleanup: Removed logs older than retention period" || echo "No changes to commit"
    git push origin ${LOG_BRANCH}
}

archive_logs() {
    local MONTH=$1
    
    if [ -z "$MONTH" ]; then
        # Archive previous month by default
        MONTH=$(date -d "1 month ago" +%Y-%m)
    fi
    
    fetch_log_branch
    
    echo -e "${BLUE}Archiving logs for ${MONTH}...${NC}"
    
    # Create archive directory
    mkdir -p ${ARCHIVE_PATH}
    
    # Find all logs for the month
    ARCHIVE_NAME="logs-archive-${MONTH}.tar.gz"
    ARCHIVE_FILE="${ARCHIVE_PATH}/${ARCHIVE_NAME}"
    
    # Create archive
    tar -czf "${ARCHIVE_FILE}" ${LOG_BASE_PATH}/${MONTH}-* 2>/dev/null || {
        echo -e "${YELLOW}No logs found for ${MONTH}${NC}"
        return
    }
    
    # Calculate archive size
    ARCHIVE_SIZE=$(du -h "${ARCHIVE_FILE}" | cut -f1)
    echo -e "${GREEN}Archive created: ${ARCHIVE_FILE} (${ARCHIVE_SIZE})${NC}"
    
    # Optionally upload to S3
    if [ -n "$AWS_S3_BUCKET" ]; then
        echo "Uploading to S3..."
        aws s3 cp "${ARCHIVE_FILE}" "s3://${AWS_S3_BUCKET}/pipeline-logs/archives/"
    fi
    
    # Remove original logs after archiving
    read -p "Remove original logs for ${MONTH}? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf ${LOG_BASE_PATH}/${MONTH}-*
        echo -e "${GREEN}Original logs removed${NC}"
    fi
    
    # Commit changes
    git add -A
    git commit -m "Archived logs for ${MONTH}" || echo "No changes to commit"
    git push origin ${LOG_BRANCH}
}

export_logs() {
    local RUN_ID=$1
    
    if [ -z "$RUN_ID" ]; then
        echo -e "${RED}Error: Please provide a RUN_ID${NC}"
        echo "Usage: $0 export [RUN_ID]"
        exit 1
    fi
    
    fetch_log_branch
    
    # Find log file
    local LOG_FILE=$(find ${LOG_BASE_PATH} -name "pipeline-logs.md" -path "*/run-${RUN_ID}/*" 2>/dev/null | head -1)
    
    if [ -z "$LOG_FILE" ]; then
        echo -e "${RED}Error: No logs found for run ${RUN_ID}${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Exporting logs for run ${RUN_ID}...${NC}"
    
    # Export to different formats
    BASE_NAME="pipeline-log-${RUN_ID}"
    
    # PDF (if pandoc is available)
    if command -v pandoc &> /dev/null; then
        pandoc "$LOG_FILE" -o "${BASE_NAME}.pdf"
        echo -e "${GREEN}Exported to PDF: ${BASE_NAME}.pdf${NC}"
    fi
    
    # HTML
    if command -v pandoc &> /dev/null; then
        pandoc "$LOG_FILE" -o "${BASE_NAME}.html" --standalone --toc
        echo -e "${GREEN}Exported to HTML: ${BASE_NAME}.html${NC}"
    fi
    
    # JSON (extract key metrics)
    echo "{" > "${BASE_NAME}.json"
    echo "  \"run_id\": \"${RUN_ID}\"," >> "${BASE_NAME}.json"
    grep "Pipeline Result:" "$LOG_FILE" | head -1 | sed 's/.*Pipeline Result: */  "status": "/' | sed 's/$/",/' >> "${BASE_NAME}.json"
    grep "Total Duration:" "$LOG_FILE" | head -1 | sed 's/.*Total Duration: */  "duration": "/' | sed 's/$/",/' >> "${BASE_NAME}.json"
    grep "Deployment URL:" "$LOG_FILE" | head -1 | sed 's/.*Deployment URL: */  "deployment_url": "/' | sed 's/$/"/' >> "${BASE_NAME}.json"
    echo "}" >> "${BASE_NAME}.json"
    echo -e "${GREEN}Exported to JSON: ${BASE_NAME}.json${NC}"
    
    # Plain text
    cp "$LOG_FILE" "${BASE_NAME}.txt"
    echo -e "${GREEN}Exported to TXT: ${BASE_NAME}.txt${NC}"
}

monitor_pipeline() {
    echo -e "${BLUE}Real-time Pipeline Monitoring${NC}"
    echo "Watching for new pipeline runs..."
    echo "Press Ctrl+C to stop"
    echo ""
    
    # Monitor GitHub API for workflow runs
    while true; do
        # This would normally poll GitHub API
        # For demonstration, we'll check for new log files
        
        fetch_log_branch > /dev/null 2>&1
        
        LATEST_RUN=$(find ${LOG_BASE_PATH} -name "pipeline-logs.md" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2)
        
        if [ -n "$LATEST_RUN" ]; then
            LATEST_TIME=$(stat -c %y "$LATEST_RUN" 2>/dev/null | cut -d' ' -f1,2)
            echo -e "${GREEN}[${LATEST_TIME}]${NC} Latest run: $(basename $(dirname "$LATEST_RUN"))"
            
            # Show status
            STATUS=$(grep "Pipeline Result:" "$LATEST_RUN" 2>/dev/null | head -1 | cut -d':' -f2 | xargs)
            if [ -n "$STATUS" ]; then
                echo "  Status: ${STATUS}"
            fi
        fi
        
        sleep 30
    done
}

# Main script logic
print_header
check_prerequisites

COMMAND=$1
shift

case $COMMAND in
    view)
        view_logs "$@"
        ;;
    list)
        list_logs "$@"
        ;;
    search)
        search_logs "$@"
        ;;
    analyze)
        analyze_metrics
        ;;
    cleanup)
        cleanup_old_logs
        ;;
    archive)
        archive_logs "$@"
        ;;
    export)
        export_logs "$@"
        ;;
    monitor)
        monitor_pipeline
        ;;
    -h|--help|help|"")
        print_usage
        ;;
    *)
        echo -e "${RED}Error: Unknown command '${COMMAND}'${NC}"
        echo ""
        print_usage
        exit 1
        ;;
esac