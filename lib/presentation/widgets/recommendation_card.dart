import 'package:flutter/material.dart';
import '../../models/recommendation_model.dart';
import '../../services/recommendation_service.dart';

class FoodRecommendationCard extends StatelessWidget {
  final FoodRecommendation recommendation;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const FoodRecommendationCard({
    Key? key,
    required this.recommendation,
    this.onTap,
    this.onAddToCart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Record view interaction
          RecommendationService.recordFoodInteraction(
            menuItemId: recommendation.menuItemId,
            interactionType: 'view',
          );
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: recommendation.image != null
                    ? Image.network(
                        recommendation.image!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.restaurant, color: Colors.grey),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.restaurant, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 12),
              
              // Food Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Recommendation Badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            recommendation.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildRecommendationBadge(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Description
                    Text(
                      recommendation.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Price and Rating
                    Row(
                      children: [
                        Text(
                          'Rs. ${recommendation.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (recommendation.averageRating != null) ...[
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 2),
                          Text(
                            recommendation.averageRating!.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Tags
                    Wrap(
                      spacing: 4,
                      children: [
                        if (recommendation.cuisine != null)
                          _buildTag(recommendation.cuisine!, Colors.blue),
                        if (recommendation.spiceLevel != null)
                          _buildSpiceLevelTag(recommendation.spiceLevel!),
                        if (recommendation.dietaryTags != null)
                          ...recommendation.dietaryTags!.take(2).map(
                            (tag) => _buildTag(tag, Colors.green),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Add to Cart Button
              if (onAddToCart != null)
                IconButton(
                  onPressed: onAddToCart,
                  icon: const Icon(Icons.add_shopping_cart),
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationBadge() {
    Color badgeColor;
    String badgeText;
    
    switch (recommendation.confidence) {
      case 'high':
        badgeColor = Colors.green;
        badgeText = 'Highly Recommended';
        break;
      case 'medium':
        badgeColor = Colors.orange;
        badgeText = 'Recommended';
        break;
      case 'low':
        badgeColor = Colors.grey;
        badgeText = 'Suggested';
        break;
      default:
        badgeColor = Colors.blue;
        badgeText = 'For You';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontSize: 10,
          color: badgeColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSpiceLevelTag(String spiceLevel) {
    Color color;
    String emoji;
    
    switch (spiceLevel.toLowerCase()) {
      case 'mild':
        color = Colors.green;
        emoji = '🌶️';
        break;
      case 'medium':
        color = Colors.orange;
        emoji = '🌶️🌶️';
        break;
      case 'hot':
        color = Colors.red;
        emoji = '🌶️🌶️🌶️';
        break;
      case 'very_hot':
        color = Colors.deepOrange;
        emoji = '🌶️🌶️🌶️🌶️';
        break;
      default:
        color = Colors.grey;
        emoji = '🌶️';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$emoji $spiceLevel',
        style: TextStyle(
          fontSize: 10,
          color: color,
        ),
      ),
    );
  }
}

class TableRecommendationCard extends StatelessWidget {
  final TableRecommendation recommendation;
  final VoidCallback? onTap;
  final VoidCallback? onReserve;

  const TableRecommendationCard({
    Key? key,
    required this.recommendation,
    this.onTap,
    this.onReserve,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Record view interaction
          RecommendationService.recordTableInteraction(
            tableId: recommendation.tableId,
            interactionType: 'view',
          );
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with rank and confidence
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#${recommendation.rank}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildConfidenceBadge(),
                ],
              ),
              const SizedBox(height: 12),
              
              // Table Image and Details
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: recommendation.table.image != null
                        ? Image.network(
                            recommendation.table.image!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[300],
                                child: const Icon(Icons.table_restaurant, color: Colors.grey),
                              );
                            },
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.table_restaurant, color: Colors.grey),
                          ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Table Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation.table.tableName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Capacity: ${recommendation.table.capacity} people',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Location: ${recommendation.table.location}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Features
                        Wrap(
                          spacing: 4,
                          children: [
                            _buildFeatureTag(recommendation.table.ambiance, Colors.purple),
                            if (recommendation.table.hasWindowView)
                              _buildFeatureTag('Window View', Colors.blue),
                            if (recommendation.table.isPrivate)
                              _buildFeatureTag('Private', Colors.green),
                            _buildFeatureTag(recommendation.table.priceTier, Colors.orange),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Explanation
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  recommendation.explanation,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Reserve Button
              if (onReserve != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onReserve,
                    child: const Text('Reserve Table'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge() {
    Color badgeColor;
    String badgeText;
    
    switch (recommendation.confidence) {
      case 'high':
        badgeColor = Colors.green;
        badgeText = 'Perfect Match';
        break;
      case 'medium':
        badgeColor = Colors.orange;
        badgeText = 'Good Match';
        break;
      case 'low':
        badgeColor = Colors.grey;
        badgeText = 'Suggested';
        break;
      default:
        badgeColor = Colors.blue;
        badgeText = 'Recommended';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontSize: 10,
          color: badgeColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFeatureTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
        ),
      ),
    );
  }
}
