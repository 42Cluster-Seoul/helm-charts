read -p "Enter the value for application name: " app_name

# Variables 
OUTPUT_DIRECTORY="../stable"
DESTINATION_DIRECTORY="$OUTPUT_DIRECTORY/$app_name"
OUTPUT_CHARTS_FILE="$DESTINATION_DIRECTORY/Chart.yaml"
OUTPUT_VALUES_FILE="$DESTINATION_DIRECTORY/values.yaml"
HELM_TEMPLATES_DIRECTORY="template/templates"
GITHUB_REPOSITORY="https://github.com/42Cluster-Seoul/helm-charts"

if [ ! -d "$DESTINATION_DIRECTORY" ]; then
  mkdir -p "$DESTINATION_DIRECTORY"
else
  rm -rf "$DESTINATION_DIRECTORY"
  mkdir -p "$DESTINATION_DIRECTORY"
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