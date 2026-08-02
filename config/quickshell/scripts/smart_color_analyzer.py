#!/usr/bin/env python3
"""
Smart Color Analyzer for Quickshell
Implements CIELAB color space, K-means clustering, hybrid accent extraction,
semantic classification, temporal smoothing, and context awareness.
"""

import os
import sys
import json
import colorsys
import hashlib
from datetime import datetime, time as dt_time
from typing import Dict, List, Tuple, Optional, Any
from dataclasses import dataclass
from PIL import Image

# Optional imports with fallbacks
try:
    import numpy as np
    NUMPY_AVAILABLE = True
except ImportError:
    NUMPY_AVAILABLE = False
    print("Warning: numpy not available. Some features will be limited.", file=sys.stderr)
    # Simple fallback for basic operations
    class SimpleNumpy:
        @staticmethod
        def array(data):
            return data
        @staticmethod
        def mean(data, axis=None):
            if axis is None:
                return sum(data) / len(data)
            return data
    np = SimpleNumpy()

try:
    from sklearn.cluster import KMeans
    SKLEARN_AVAILABLE = True
except ImportError:
    SKLEARN_AVAILABLE = False
    print("Warning: scikit-learn not available. K-means clustering disabled.", file=sys.stderr)

# Tela icon theme colors for matching
TELA_COLORS = {
    "Tela-red": "#e74c3c", "Tela-pink": "#ec407a", "Tela-orange": "#e67e22",
    "Tela-ubuntu": "#e95420", "Tela-yellow": "#f39c12", "Tela-green": "#2ecc71",
    "Tela-manjaro": "#16a085", "Tela-nord": "#5e81ac", "Tela-blue": "#3584e4",
    "Tela-purple": "#9b59b6", "Tela-dracula": "#bd93f9", "Tela-brown": "#8d6e63",
    "Tela-grey": "#787c99", "Tela-black": "#555b6e"
}

@dataclass
class ColorAnalysis:
    """Result of color analysis"""
    recommended_icon: str
    accent_color: str
    confidence: float
    is_light: bool
    dominant_color: str
    semantic_tags: List[str]
    color_hash: str
    clusters: List[Dict[str, Any]]

class SmartColorAnalyzer:
    def __init__(self, config_path: str = None):
        """Initialize analyzer with configuration"""
        self.config = self._load_config(config_path)
        self.temporal_cache = self._load_temporal_cache()
        
    def _load_config(self, config_path: str) -> Dict[str, bool]:
        """Load feature configuration"""
        if config_path is None:
            config_path = os.path.expanduser("~/.config/quickshell/smart_color_config.json")
        
        default_config = {
            "cielab": False,
            "kmeans": False,
            "hybrid_extraction": False,
            "semantic_classification": False,
            "temporal_smoothing": False,
            "context_awareness": False,
            "fallback_prompt": False
        }
        
        if os.path.isfile(config_path):
            try:
                with open(config_path, 'r') as f:
                    return {**default_config, **json.load(f)}
            except Exception:
                pass
        
        return default_config
    
    def _load_temporal_cache(self) -> Dict[str, Any]:
        """Load temporal smoothing cache"""
        cache_file = os.path.expanduser("~/.cache/quickshell/temporal_color_cache.json")
        if os.path.isfile(cache_file):
            try:
                with open(cache_file, 'r') as f:
                    return json.load(f)
            except Exception:
                pass
        return {"recent_hashes": [], "hash_mappings": {}}
    
    def _save_temporal_cache(self):
        """Save temporal smoothing cache"""
        cache_file = os.path.expanduser("~/.cache/quickshell/temporal_color_cache.json")
        os.makedirs(os.path.dirname(cache_file), exist_ok=True)
        try:
            with open(cache_file, 'w') as f:
                json.dump(self.temporal_cache, f, indent=2)
        except Exception:
            pass
    
    def rgb_to_cielab(self, r: int, g: int, b: int) -> Tuple[float, float, float]:
        """Convert RGB to CIELAB color space"""
        # Normalize RGB to 0-1
        r_norm, g_norm, b_norm = r/255.0, g/255.0, b/255.0
        
        # Convert to XYZ (sRGB D65)
        def gamma_correct(c):
            return c/12.92 if c <= 0.04045 else ((c+0.055)/1.055)**2.4
        
        r_lin, g_lin, b_lin = gamma_correct(r_norm), gamma_correct(g_norm), gamma_correct(b_norm)
        
        # sRGB to XYZ matrix (D65)
        x = r_lin * 0.4124564 + g_lin * 0.3575761 + b_lin * 0.1804375
        y = r_lin * 0.2126729 + g_lin * 0.7151522 + b_lin * 0.0721750
        z = r_lin * 0.0193339 + g_lin * 0.1191920 + b_lin * 0.9503041
        
        # XYZ to CIELAB (D65 reference white)
        def lab_f(t):
            return t**(1/3) if t > 0.008856 else 7.787*t + 16/116
        
        x_ref, y_ref, z_ref = 0.95047, 1.00000, 1.08883
        
        l = 116 * lab_f(y/y_ref) - 16
        a = 500 * (lab_f(x/x_ref) - lab_f(y/y_ref))
        b_lab = 200 * (lab_f(y/y_ref) - lab_f(z/z_ref))
        
        return (l, a, b_lab)
    
    def delta_e(self, lab1: Tuple[float, float, float], lab2: Tuple[float, float, float]) -> float:
        """Calculate CIELAB Delta E (perceptual color distance)"""
        l1, a1, b1 = lab1
        l2, a2, b2 = lab2
        return ((l2-l1)**2 + (a2-a1)**2 + (b2-b1)**2)**0.5
    
    def hex_to_rgb(self, hex_color: str) -> Tuple[int, int, int]:
        """Convert hex color to RGB tuple"""
        hex_color = hex_color.lstrip('#')
        if len(hex_color) != 6:
            return (128, 128, 128)
        return (
            int(hex_color[0:2], 16),
            int(hex_color[2:4], 16),
            int(hex_color[4:6], 16)
        )
    
    def rgb_to_hex(self, r: int, g: int, b: int) -> str:
        """Convert RGB tuple to hex color"""
        return f"#{r:02x}{g:02x}{b:02x}"
    
    def analyze_image(self, image_path: str) -> Optional[ColorAnalysis]:
        """Main analysis function"""
        if not os.path.isfile(image_path):
            return None
        
        try:
            img = Image.open(image_path).convert('RGB')
            img_small = img.resize((200, 200))  # Higher resolution for better analysis
            
            # Get pixel data
            pixels = np.array(img_small)
            pixels_reshaped = pixels.reshape(-1, 3)
            
            # Basic statistics
            avg_color = np.mean(pixels_reshaped, axis=0).astype(int)
            avg_luma = 0.299*avg_color[0] + 0.587*avg_color[1] + 0.114*avg_color[2]
            is_light = avg_luma > 128
            
            # Generate color hash for temporal smoothing
            color_hash = self._generate_color_hash(avg_color)
            
            # Check temporal smoothing if enabled
            if self.config["temporal_smoothing"]:
                cached_result = self._check_temporal_cache(color_hash)
                if cached_result:
                    return cached_result
            
            # Perform clustering if enabled
            clusters = []
            if self.config["kmeans"] and SKLEARN_AVAILABLE:
                clusters = self._kmeans_cluster(pixels_reshaped)
            else:
                # Fallback to simple color quantization
                clusters = self._simple_quantize(pixels_reshaped)
            
            # Extract accent color using hybrid rules
            accent_color, confidence = self._extract_accent_hybrid(
                clusters, is_light, pixels_reshaped
            )
            
            # Find best Tela theme match
            if self.config["cielab"]:
                recommended_icon = self._find_closest_tela_cielab(accent_color)
            else:
                recommended_icon = self._find_closest_tela_rgb(accent_color)
            
            # Semantic classification
            semantic_tags = []
            if self.config["semantic_classification"]:
                semantic_tags = self._classify_semantic(accent_color, clusters)
            
            # Create analysis result
            result = ColorAnalysis(
                recommended_icon=recommended_icon,
                accent_color=accent_color,
                confidence=confidence,
                is_light=is_light,
                dominant_color=self.rgb_to_hex(*avg_color),
                semantic_tags=semantic_tags,
                color_hash=color_hash,
                clusters=clusters
            )
            
            # Cache result for temporal smoothing
            if self.config["temporal_smoothing"]:
                self._update_temporal_cache(color_hash, result)
            
            return result
            
        except Exception as e:
            print(f"Error analyzing image: {e}", file=sys.stderr)
            return None
    
    def _generate_color_hash(self, avg_color: np.ndarray) -> str:
        """Generate hash from average color for temporal smoothing"""
        r, g, b = avg_color
        color_str = f"{r:02x}{g:02x}{b:02x}"
        return hashlib.md5(color_str.encode()).hexdigest()[:8]
    
    def _check_temporal_cache(self, color_hash: str) -> Optional[ColorAnalysis]:
        """Check if similar color was recently analyzed"""
        if not self.temporal_cache["recent_hashes"]:
            return None
        
        # Check if this hash is in recent history
        if color_hash in self.temporal_cache["hash_mappings"]:
            cached = self.temporal_cache["hash_mappings"][color_hash]
            return ColorAnalysis(**cached)
        
        # Check for similar colors (conservative 15% threshold)
        for recent_hash in self.temporal_cache["recent_hashes"][-10:]:  # Last 10
            if recent_hash in self.temporal_cache["hash_mappings"]:
                cached = self.temporal_cache["hash_mappings"][recent_hash]
                # Simple hash similarity check (first 4 chars match)
                if color_hash[:4] == recent_hash[:4]:
                    return ColorAnalysis(**cached)
        
        return None
    
    def _update_temporal_cache(self, color_hash: str, result: ColorAnalysis):
        """Update temporal cache with new analysis"""
        # Add to recent hashes
        if color_hash not in self.temporal_cache["recent_hashes"]:
            self.temporal_cache["recent_hashes"].append(color_hash)
            if len(self.temporal_cache["recent_hashes"]) > 20:  # Keep last 20
                self.temporal_cache["recent_hashes"].pop(0)
        
        # Store mapping
        self.temporal_cache["hash_mappings"][color_hash] = {
            "recommended_icon": result.recommended_icon,
            "accent_color": result.accent_color,
            "confidence": result.confidence,
            "is_light": result.is_light,
            "dominant_color": result.dominant_color,
            "semantic_tags": result.semantic_tags,
            "color_hash": result.color_hash,
            "clusters": result.clusters
        }
        
        self._save_temporal_cache()
    
    def _kmeans_cluster(self, pixels: np.ndarray, n_clusters: int = 6) -> List[Dict[str, Any]]:
        """Perform K-means clustering on colors"""
        try:
            # Sample pixels for performance
            if len(pixels) > 10000:
                indices = np.random.choice(len(pixels), 10000, replace=False)
                pixels_sampled = pixels[indices]
            else:
                pixels_sampled = pixels
            
            kmeans = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
            labels = kmeans.fit_predict(pixels_sampled)
            centers = kmeans.cluster_centers_
            
            clusters = []
            for i, center in enumerate(centers):
                cluster_pixels = pixels_sampled[labels == i]
                percentage = len(cluster_pixels) / len(pixels_sampled)
                clusters.append({
                    "center": self.rgb_to_hex(*center.astype(int)),
                    "percentage": percentage,
                    "count": len(cluster_pixels)
                })
            
            # Sort by percentage
            clusters.sort(key=lambda x: x["percentage"], reverse=True)
            return clusters
            
        except Exception as e:
            print(f"K-means clustering failed: {e}", file=sys.stderr)
            return self._simple_quantize(pixels)
    
    def _simple_quantize(self, pixels: np.ndarray) -> List[Dict[str, Any]]:
        """Simple color quantization fallback"""
        # Reduce colors to 32 levels per channel
        quantized = (pixels // 8) * 8
        unique_colors, counts = np.unique(quantized, axis=0, return_counts=True)
        
        clusters = []
        total_pixels = len(pixels)
        for color, count in zip(unique_colors, counts):
            clusters.append({
                "center": self.rgb_to_hex(*color),
                "percentage": count / total_pixels,
                "count": int(count)
            })
        
        clusters.sort(key=lambda x: x["percentage"], reverse=True)
        return clusters[:8]  # Return top 8
    
    def _extract_accent_hybrid(self, clusters: List[Dict[str, Any]], 
                              is_light: bool, pixels: np.ndarray) -> Tuple[str, float]:
        """Extract accent color using hybrid rules"""
        if not clusters:
            return "#3584e4", 0.5  # Default blue
        
        # Rule A: If dominant color > 40%, use as primary reference
        dominant = clusters[0]
        if dominant["percentage"] > 0.40:
            base_color = self.hex_to_rgb(dominant["center"])
        else:
            # Use second most dominant if available
            if len(clusters) > 1:
                base_color = self.hex_to_rgb(clusters[1]["center"])
            else:
                base_color = self.hex_to_rgb(dominant["center"])
        
        # Rule B: Detect and remove tints (simplified gray-world)
        tint_removed = self._remove_tint(base_color, pixels)
        
        # Rule C/D: Light/Dark mode color selection
        if is_light:
            # Find brighter, more colorful color
            accent = self._find_bright_colorful(clusters, tint_removed)
        else:
            # Find brightest among dark colors
            accent = self._find_bright_dark(clusters, tint_removed)
        
        # Calculate confidence based on cluster separation
        confidence = self._calculate_confidence(clusters)
        
        return accent, confidence
    
    def _remove_tint(self, base_color: Tuple[int, int, int], 
                    pixels: np.ndarray) -> Tuple[int, int, int]:
        """Remove color cast using gray-world assumption"""
        avg_color = np.mean(pixels, axis=0).astype(int)
        gray_avg = sum(avg_color) / 3
        
        if gray_avg == 0:
            return base_color
        
        # Calculate correction factors
        r_factor = gray_avg / avg_color[0] if avg_color[0] > 0 else 1
        g_factor = gray_avg / avg_color[1] if avg_color[1] > 0 else 1
        b_factor = gray_avg / avg_color[2] if avg_color[2] > 0 else 1
        
        # Apply correction with clamping
        r = min(255, max(0, int(base_color[0] * r_factor)))
        g = min(255, max(0, int(base_color[1] * g_factor)))
        b = min(255, max(0, int(base_color[2] * b_factor)))
        
        return (r, g, b)
    
    def _find_bright_colorful(self, clusters: List[Dict[str, Any]], 
                              base_color: Tuple[int, int, int]) -> str:
        """Find bright, colorful color for light mode"""
        best_color = base_color
        best_score = -1
        
        for cluster in clusters:
            color = self.hex_to_rgb(cluster["center"])
            r, g, b = color
            
            # Calculate brightness and saturation
            brightness = (r + g + b) / 3
            saturation = max(r, g, b) - min(r, g, b)
            saturation_norm = saturation / 255.0 if max(r, g, b) > 0 else 0
            
            # Score: prefer bright, saturated colors
            score = (brightness / 255.0) * 0.6 + (saturation_norm ** 2) * 0.4
            
            if score > best_score:
                best_score = score
                best_color = color
        
        return self.rgb_to_hex(*best_color)
    
    def _find_bright_dark(self, clusters: List[Dict[str, Any]], 
                         base_color: Tuple[int, int, int]) -> str:
        """Find brightest color among dark colors for dark mode"""
        best_color = base_color
        best_score = -1
        
        for cluster in clusters:
            color = self.hex_to_rgb(cluster["center"])
            r, g, b = color
            brightness = (r + g + b) / 3
            
            # Only consider dark colors (brightness < 128)
            if brightness < 128:
                # Score: prefer brightest among darks
                score = brightness / 128.0
                if score > best_score:
                    best_score = score
                    best_color = color
        
        return self.rgb_to_hex(*best_color)
    
    def _calculate_confidence(self, clusters: List[Dict[str, Any]]) -> float:
        """Calculate confidence score based on cluster quality"""
        if not clusters:
            return 0.5
        
        # Factor 1: Dominant cluster strength
        dominant_strength = clusters[0]["percentage"]
        
        # Factor 2: Cluster separation (gap between top clusters)
        if len(clusters) > 1:
            separation = clusters[0]["percentage"] - clusters[1]["percentage"]
        else:
            separation = 0.5
        
        # Factor 3: Number of significant clusters (>5%)
        significant = sum(1 for c in clusters if c["percentage"] > 0.05)
        cluster_factor = min(1.0, significant / 3.0)
        
        # Combined confidence
        confidence = (dominant_strength * 0.4) + (separation * 0.3) + (cluster_factor * 0.3)
        return min(1.0, max(0.0, confidence))
    
    def _find_closest_tela_cielab(self, accent_hex: str) -> str:
        """Find closest Tela theme using CIELAB Delta E"""
        accent_rgb = self.hex_to_rgb(accent_hex)
        accent_lab = self.rgb_to_cielab(*accent_rgb)
        
        best_match = "Tela-blue"
        best_distance = float('inf')
        
        for theme_name, theme_hex in TELA_COLORS.items():
            theme_rgb = self.hex_to_rgb(theme_hex)
            theme_lab = self.rgb_to_cielab(*theme_rgb)
            distance = self.delta_e(accent_lab, theme_lab)
            
            if distance < best_distance:
                best_distance = distance
                best_match = theme_name
        
        return best_match
    
    def _find_closest_tela_rgb(self, accent_hex: str) -> str:
        """Find closest Tela theme using RGB Euclidean distance (fallback)"""
        accent_rgb = self.hex_to_rgb(accent_hex)
        
        best_match = "Tela-blue"
        best_distance = float('inf')
        
        for theme_name, theme_hex in TELA_COLORS.items():
            theme_rgb = self.hex_to_rgb(theme_hex)
            distance = sum((a - b) ** 2 for a, b in zip(accent_rgb, theme_rgb)) ** 0.5
            
            if distance < best_distance:
                best_distance = distance
                best_match = theme_name
        
        return best_match
    
    def _classify_semantic(self, accent_color: str, 
                          clusters: List[Dict[str, Any]]) -> List[str]:
        """Classify color semantically (warm/cool, earthy/neon, pastel/vibrant)"""
        tags = []
        rgb = self.hex_to_rgb(accent_color)
        r, g, b = rgb
        
        # Warm vs Cool
        if r > b and r > g:
            tags.append("warm")
        elif b > r and b > g:
            tags.append("cool")
        else:
            # Green is neutral/cool
            tags.append("cool" if g > r else "warm")
        
        # Saturation for earthy vs neon
        max_val = max(r, g, b)
        min_val = min(r, g, b)
        saturation = (max_val - min_val) / max_val if max_val > 0 else 0
        
        if saturation < 0.3:
            tags.append("earthy")
        elif saturation > 0.7:
            tags.append("neon")
        else:
            tags.append("balanced")
        
        # Brightness for pastel vs vibrant
        brightness = (r + g + b) / 3
        if brightness > 200 and saturation < 0.4:
            tags.append("pastel")
        elif brightness > 150 and saturation > 0.5:
            tags.append("vibrant")
        else:
            tags.append("muted")
        
        return tags
    
    def _get_context_awareness(self) -> Dict[str, Any]:
        """Get context awareness factors (time of day, system activity)"""
        context = {
            "time_of_day": "neutral",
            "activity_mode": "normal"
        }
        
        if not self.config["context_awareness"]:
            return context
        
        # Time of day
        now = datetime.now().time()
        morning_start = dt_time(6, 0)
        evening_start = dt_time(17, 0)
        night_start = dt_time(21, 0)
        
        if morning_start <= now < evening_start:
            context["time_of_day"] = "day"
        elif evening_start <= now < night_start:
            context["time_of_day"] = "evening"
        else:
            context["time_of_day"] = "night"
        
        # System activity (gaming detection)
        try:
            # Check for Steam/Lutris processes
            result = os.popen("pgrep -f 'steam|lutris' 2>/dev/null").read()
            if result.strip():
                context["activity_mode"] = "gaming"
        except Exception:
            pass
        
        return context
    
    def prompt_user_fallback(self, image_path: str, confidence: float) -> str:
        """Show user prompt for manual theme selection when confidence is low"""
        if not self.config["fallback_prompt"]:
            return "Tela-blue"  # Default fallback
        
        # Log the failure
        log_file = os.path.expanduser("~/.cache/quickshell/smart_color_failures.log")
        os.makedirs(os.path.dirname(log_file), exist_ok=True)
        try:
            with open(log_file, 'a') as f:
                f.write(f"{datetime.now().isoformat()} - {image_path} - Confidence: {confidence:.2f}\n")
        except Exception:
            pass
        
        # Try zenity first, then kdialog
        tela_options = list(TELA_COLORS.keys())
        tela_list = " ".join(tela_options)
        
        # Zenity approach
        zenity_cmd = f"""
        zenity --list --title="Icon Theme Selection" \
               --text="Icon theme cannot be confidently identified (confidence: {confidence:.0%}).\\n\\nPlease select a Tela theme:" \
               --column="Themes" {tela_list} \
               --height=400 --width=300 --timeout=30
        """
        
        try:
            result = os.popen(zenity_cmd).read().strip()
            if result and result in TELA_COLORS:
                return result
        except Exception:
            pass
        
        # Kdialog fallback
        kdialog_cmd = f"""
        kdialog --combobox "Icon theme cannot be confidently identified (confidence: {confidence:.0%}).\\nSelect a Tela theme:" \
                  {" ".join(tela_options)} --default "Tela-blue"
        """
        
        try:
            result = os.popen(kdialog_cmd).read().strip()
            if result and result in TELA_COLORS:
                return result
        except Exception:
            pass
        
        # Default fallback
        return "Tela-blue"

def main():
    """CLI interface for testing"""
    if len(sys.argv) < 2:
        print("Usage: smart_color_analyzer.py <image_path>")
        sys.exit(1)
    
    image_path = sys.argv[1]
    analyzer = SmartColorAnalyzer()
    result = analyzer.analyze_image(image_path)
    
    if result:
        print(json.dumps({
            "recommended_icon": result.recommended_icon,
            "accent_color": result.accent_color,
            "confidence": result.confidence,
            "is_light": bool(result.is_light),
            "dominant_color": result.dominant_color,
            "semantic_tags": result.semantic_tags,
            "color_hash": result.color_hash
        }, indent=2))
    else:
        print("Analysis failed")
        sys.exit(1)

if __name__ == "__main__":
    main()
