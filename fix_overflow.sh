#!/bin/bash
# Script pour corriger les débordements dans dashboard_screen.dart

FILE="/home/markupsafe/Documents/CashFlow/lib/presentation/screens/dashboard_screen.dart"

# Remplacer "percentage * 250" par "min(percentage * 200, constraints.maxWidth * percentage)"
sed -i 's/percentage \* 250/min(percentage * 200, 0.95 * MediaQuery.of(context).size.width * percentage)/g' "$FILE"

echo "Correction terminée pour $FILE"
