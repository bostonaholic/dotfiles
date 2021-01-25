# Installed with asdf
# export PATH=/usr/local/opt/postgresql@10/bin:$PATH

function asdf() {
    case $1 in
        "start")
            case $2 in
                "es"|"elasticsearch")
                    `asdf which elasticsearch` -p /tmp/elasticsearch-pid -d
                    echo "[STARTED] Elasticsearch `asdf current elasticsearch`"
                    ;;
                "kibana")
                    nohup `echo $(asdf which kibana) --log-file $(asdf where kibana)/kibana.log` >/dev/null&
                    echo "[STARTED] Kibana `asdf current kibana`"
                    ;;
                *)
                    echo "Plugin not found. Run \"asdf plugin-list\" to find available plugins."
                    ;;
            esac
            ;;
        "stop")
            case $2 in
                "es"|"elasticsearch")
                    kill -SIGTERM $(cat /tmp/elasticsearch-pid | sed 's/%//')
                    echo "[STOPPED] Elasticsearch `asdf current elasticsearch`"
                    ;;
                "kibana")
                    kill $(ps aux | grep "$(asdf where kibana)" | awk '{print $2}')
                    echo "[STOPPED] Kibana `asdf current kibana`"
                    ;;
                *)
                    echo "Plugin not found. Run \"asdf plugin-list\" to find available plugins."
                    ;;
            esac
            ;;
        "restart")
            case $2 in
                "es"|"elasticsearch")
                    asdf stop elasticsearch
                    asdf start elasticsearch
                    ;;
                "kibana")
                    asdf stop kibana
                    asdf start kibana
                    ;;
                *)
                    echo "Plugin not found. Run \"asdf plugin-list\" to find available plugins."
                    ;;
            esac
            ;;
        *)
            $ASDF_BIN/asdf "$@"
            ;;
    esac
}
