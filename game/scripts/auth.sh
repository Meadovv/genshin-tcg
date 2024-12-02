systems=(
    
)

# Loop through each system and run the command
for system in "${systems[@]}"; do
  sozo --dev auth grant writer dragark,$system
done
