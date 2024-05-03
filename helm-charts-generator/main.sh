read -p "Enter the value for application name: " app_name

# Variables 
OUTPUT_DIRECTORY="../stable"
DESTINATION_DIRECTORY="$OUTPUT_DIRECTORY/$app_name"
OUTPUT_CHARTS_FILE="$DESTINATION_DIRECTORY/Chart.yaml"
OUTPUT_VALUES_FILE="$DESTINATION_DIRECTORY/values.yaml"
HELM_TEMPLATES_DIRECTORY="template/templates"

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

echo -e "\n🪽 New Helm Charts created with app name: $app_name \n"

echo -e "✅ Lint Check for application: $app_name\n"

helm lint $DESTINATION_DIRECTORY

echo -e "\n📦 Packaging for application: $app_name\n"

helm package $DESTINATION_DIRECTORY -d $OUTPUT_DIRECTORY

echo -e "\n📝 Adding index for application: $app_name\n"

helm repo index $OUTPUT_DIRECTORY