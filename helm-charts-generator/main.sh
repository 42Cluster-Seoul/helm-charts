
# Variables 
OUTPUT_DIRECTORY="../stable"
HELM_TEMPLATES_DIRECTORY="template/templates"
GITHUB_REPOSITORY="https://github.com/42Cluster-Seoul/helm-charts"

create_application() {
  read -p "Enter the value for application name: " app_name

  DESTINATION_DIRECTORY="$OUTPUT_DIRECTORY/$app_name"
  OUTPUT_CHARTS_FILE="$DESTINATION_DIRECTORY/Chart.yaml"
  OUTPUT_VALUES_FILE="$DESTINATION_DIRECTORY/values.yaml"

  if [ ! -d "$DESTINATION_DIRECTORY" ]; then
    mkdir -p "$DESTINATION_DIRECTORY"
  else
    while true; do
      read -p "Application already exists. Do you want to overwrite it? (y/n): " overwrite
      if [ "$overwrite" == "n" ]; then
        echo "Stop creating application. Exiting program."
        exit 0
      elif [ "$overwrite" == "y" ]; then
        rm -rf "$DESTINATION_DIRECTORY"
        mkdir -p "$DESTINATION_DIRECTORY"
        echo "Overwriting the application: $app_name"
        break
      else
        echo "Invalid input. Please enter 'y' or 'n'."
      fi
    done
  fi

  cp template/values.yaml.template $OUTPUT_VALUES_FILE
  cp template/Chart.yaml.template $OUTPUT_CHARTS_FILE

  sed -i.tmp "s/\${app_name}/$app_name/g" $OUTPUT_CHARTS_FILE

  read -p "Enter replicas count: " replicas_count
  read -p "Enter image url: " image_url
  read -p "Enter port number: " port_number

  sed -i.tmp \
      -e "s/\${app_name}/$app_name/g" \
      -e "s/\${replicas_count}/$replicas_count/g" \
      -e "s/\${image_url}/$image_url/g" \
      -e "s/\${port_number}/$port_number/g" \
      "$OUTPUT_VALUES_FILE"

  rm -f "$OUTPUT_CHARTS_FILE.tmp" "$OUTPUT_VALUES_FILE.tmp"

  cp -r "$HELM_TEMPLATES_DIRECTORY" "$DESTINATION_DIRECTORY"

  sed -i.tmp "s/\${app_name}/$app_name/g" "$DESTINATION_DIRECTORY/templates/application.yaml"

  rm -f "$DESTINATION_DIRECTORY/templates/application.yaml.tmp"

  mv "$DESTINATION_DIRECTORY/templates/application.yaml" "$OUTPUT_DIRECTORY/$app_name-applcation.yaml"

  echo -e "\n🪽 New Helm Charts created with app name: $app_name \n"

  echo -e "✅ Lint Check for application: $app_name\n"

  helm lint $DESTINATION_DIRECTORY

  echo -e "⏫ Uploading Helm Chart to Github Repository: $GITHUB_REPOSITORY \n"

  git add $OUTPUT_DIRECTORY
  git commit -m "Added new application: $app_name"
  git push origin main

  echo -e "\n🚀 Applying for application: $app_name-application.yaml\n"

  kubectl create -f $OUTPUT_DIRECTORY/$app_name-applcation.yaml
}

argocd_login() {
  if argocd app list > /dev/null 2>&1; then
    echo "🔑 ArgoCD is already logged in."
  else
    echo "🔑 Logging into ArgoCD"
    local argocd_server=$(kubectl get svc argocd-server -n argocd | awk 'NR==2 {print $3}')
    argocd login $argocd_server
  fi
}

display_applications() {
  argocd app list
}

delete_application() {
  local output=$(argocd app list)
  local total_apps=$(echo "$output" | awk 'END {print NR-1}')
  if [ $total_apps -eq 0 ]; then
    echo "❌ No applications found."
  else
    local app_names=$(argocd app list | awk 'NR > 1 {print $1}')
    IFS=$'\n' read -d '' -r -a app_array <<< "$app_names"
    local length=${#app_array[@]}

    for ((i=0; i<$length; i++)); do
      echo "$(($i+1))) ${app_array[$i]}"
    done
    read -p "Enter the application number to delete: " app_number
    local app_name=${app_array[$((app_number-1))]}
    echo $app_name
    argocd app delete $app_name
  fi
}

main() {
  echo "🚀 Helm Charts Generator"
  echo "========================"
  echo "📝 This script will help you to create Helm Charts for your application."
  echo "📝 You can also deploy the application using the generated Helm Charts."

  while true; do
    echo "========================"
    echo "📥 Select an option "
    echo "1. Create Application"
    echo "2. Delete Application"
    echo "3. Display Currently Deployed Applications"
    echo "4. Exit"
    echo "========================"

    read -p "✅ Enter your choice: " choice

    case $choice in
          1)
              create_application
              ;;
          2)
              argocd_login
              display_applications
              delete_application
              ;;
          3)
              argocd_login
              display_applications
              ;;
          4)
              echo "❌ Exiting program"
              exit 0
              ;;
          *)
              echo "Invalid choice. Please enter a number between 1 and 4."
              ;;
      esac

  done
}

main