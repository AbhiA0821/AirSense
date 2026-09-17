"""
Multi-Group Health Classification and Advisory Module.
Provides structured, non-medical health advisories based on the National Air Quality Index (NAQI)
categories across four key demographic groups:
1. General Public
2. Children and Teenagers
3. Elderly (65+)
4. Asthmatic & Respiratory / Cardiovascular Sensitive Individuals
"""

from typing import Dict, Any, List

AQI_CATEGORIES = [
    {"min": 0, "max": 50, "category": "Good", "color": "#10b981", "severity": "Low"},
    {"min": 51, "max": 100, "category": "Satisfactory", "color": "#84cc16", "severity": "Minor"},
    {"min": 101, "max": 200, "category": "Moderate", "color": "#f59e0b", "severity": "Moderate"},
    {"min": 201, "max": 300, "category": "Poor", "color": "#f97316", "severity": "Unhealthy"},
    {"min": 301, "max": 400, "category": "Very Poor", "color": "#ef4444", "severity": "Severe"},
    {"min": 401, "max": 9999, "category": "Severe", "color": "#7f1d1d", "severity": "Hazardous"}
]

def get_aqi_category(aqi: float) -> Dict[str, Any]:
    for cat in AQI_CATEGORIES:
        if cat["min"] <= aqi <= cat["max"]:
            return cat
    return AQI_CATEGORIES[-1]

def get_multi_group_advisory(aqi: float) -> Dict[str, Any]:
    """
    Returns demographic-specific health precautions and guidance based on current/predicted AQI.
    """
    cat = get_aqi_category(aqi)
    category_name = cat["category"]

    advisories = {}

    if category_name == "Good":
        advisories = {
            "general_public": {
                "risk_level": "Minimal",
                "guidance": "Air quality is ideal for all routine outdoor exercises, sports, and ventilation.",
                "mask_recommended": False,
                "outdoor_activity": "Unrestricted"
            },
            "children": {
                "risk_level": "Minimal",
                "guidance": "Completely safe for outdoor play, recess, and physical education.",
                "mask_recommended": False,
                "outdoor_activity": "Unrestricted"
            },
            "elderly": {
                "risk_level": "Minimal",
                "guidance": "Safe for morning walks and outdoor leisure without restriction.",
                "mask_recommended": False,
                "outdoor_activity": "Unrestricted"
            },
            "sensitive_groups": {
                "risk_level": "Minimal",
                "guidance": "Very low risk of respiratory irritation or exacerbations.",
                "mask_recommended": False,
                "outdoor_activity": "Normal"
            }
        }
    elif category_name == "Satisfactory":
        advisories = {
            "general_public": {
                "risk_level": "Low",
                "guidance": "Air quality is acceptable. Normal outdoor activities can be maintained.",
                "mask_recommended": False,
                "outdoor_activity": "Normal"
            },
            "children": {
                "risk_level": "Low",
                "guidance": "Safe for standard outdoor play. Monitor exceptionally sensitive children.",
                "mask_recommended": False,
                "outdoor_activity": "Normal"
            },
            "elderly": {
                "risk_level": "Low",
                "guidance": "Comfortable for outdoor activities. No special precautions required.",
                "mask_recommended": False,
                "outdoor_activity": "Normal"
            },
            "sensitive_groups": {
                "risk_level": "Minor",
                "guidance": "Minor breathing discomfort possible for exceptionally sensitive individuals.",
                "mask_recommended": False,
                "outdoor_activity": "Normal (keep reliever inhaler handy)"
            }
        }
    elif category_name == "Moderate":
        advisories = {
            "general_public": {
                "risk_level": "Moderate",
                "guidance": "May cause breathing discomfort to people with lung disease, asthma, or heart conditions.",
                "mask_recommended": False,
                "outdoor_activity": "Normal; reduce unusually intense prolonged exertion"
            },
            "children": {
                "risk_level": "Moderate",
                "guidance": "Allow outdoor play, but provide breaks during vigorous exertion.",
                "mask_recommended": False,
                "outdoor_activity": "Moderated"
            },
            "elderly": {
                "risk_level": "Moderate",
                "guidance": "Take more breaks during outdoor strolls. Avoid heavy yard work or exertion.",
                "mask_recommended": False,
                "outdoor_activity": "Light"
            },
            "sensitive_groups": {
                "risk_level": "Elevated",
                "guidance": "Noticeable cough or irritation possible. Keep rescue medication accessible.",
                "mask_recommended": True,
                "outdoor_activity": "Limit prolonged strenuous outdoor activity"
            }
        }
    elif category_name == "Poor":
        advisories = {
            "general_public": {
                "risk_level": "High",
                "guidance": "Breathing discomfort on prolonged exposure. Healthy people may experience mild irritation.",
                "mask_recommended": True,
                "outdoor_activity": "Reduce prolonged outdoor exertion"
            },
            "children": {
                "risk_level": "High",
                "guidance": "Limit prolonged outdoor running or competitive sports. Keep classroom windows closed during peak hours.",
                "mask_recommended": True,
                "outdoor_activity": "Restrict prolonged exertion"
            },
            "elderly": {
                "risk_level": "High",
                "guidance": "Reschedule early morning or evening walks to hours with better dispersion. Remain indoors where possible.",
                "mask_recommended": True,
                "outdoor_activity": "Avoid strenuous outdoor activities"
            },
            "sensitive_groups": {
                "risk_level": "Severe",
                "guidance": "Significant risk of asthma attacks or shortness of breath. Wear N95 respirator if stepping outside.",
                "mask_recommended": True,
                "outdoor_activity": "Avoid outdoor activities; use air purifiers indoors"
            }
        }
    elif category_name == "Very Poor":
        advisories = {
            "general_public": {
                "risk_level": "Very High",
                "guidance": "Respiratory illness on prolonged exposure. Significant throat and eye irritation likely.",
                "mask_recommended": True,
                "outdoor_activity": "Avoid non-essential outdoor travel and workouts"
            },
            "children": {
                "risk_level": "Very High",
                "guidance": "Cancel outdoor sports, recess, and school assemblies. Keep children indoors.",
                "mask_recommended": True,
                "outdoor_activity": "Strictly indoor activities only"
            },
            "elderly": {
                "risk_level": "Very High",
                "guidance": "Stay indoors with windows closed. Avoid any outdoor physical activity.",
                "mask_recommended": True,
                "outdoor_activity": "Strictly indoor only"
            },
            "sensitive_groups": {
                "risk_level": "Critical",
                "guidance": "High probability of acute respiratory symptoms. Keep emergency contacts and medications immediately ready.",
                "mask_recommended": True,
                "outdoor_activity": "Strictly indoors; run HEPA air filtration"
            }
        }
    else:  # Severe
        advisories = {
            "general_public": {
                "risk_level": "Hazardous",
                "guidance": "Emergency conditions. Entire population is likely to be affected. Serious health impacts on healthy individuals.",
                "mask_recommended": True,
                "outdoor_activity": "Prohibited / Emergency indoor protocol"
            },
            "children": {
                "risk_level": "Hazardous",
                "guidance": "Severe toxic exposure hazard. Schools advised to suspend physical attendance or seal classrooms.",
                "mask_recommended": True,
                "outdoor_activity": "Strictly prohibited"
            },
            "elderly": {
                "risk_level": "Hazardous",
                "guidance": "Extreme cardiovascular and respiratory stress hazard. Remain indoors in sealed environments.",
                "mask_recommended": True,
                "outdoor_activity": "Strictly prohibited"
            },
            "sensitive_groups": {
                "risk_level": "Life-Threatening",
                "guidance": "Immediate trigger for severe pulmonary or cardiac episodes. Continuous indoor air purification required.",
                "mask_recommended": True,
                "outdoor_activity": "Strictly prohibited"
            }
        }

    return {
        "aqi": round(aqi, 2),
        "category": category_name,
        "color": cat["color"],
        "severity": cat["severity"],
        "advisories": advisories
    }

get_group_advisories = get_multi_group_advisory

