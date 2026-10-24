import { useState, useRef, useEffect } from "react";
import { sendAirGuideChat } from "../lib/api";

function EvaluationPanel({ evaluation }) {
  const [expanded, setExpanded] = useState(false);

  if (!evaluation) return null;

  const {
    status = "completed",
    latency_ms,
    latency_display = latency_ms ? `${latency_ms}ms` : "N/A",
    generation_latency_ms,
    generation_latency_display = generation_latency_ms ? `${generation_latency_ms}ms` : "N/A",
    end_to_end_latency_ms,
    end_to_end_latency_display = end_to_end_latency_ms ? `${end_to_end_latency_ms}ms` : latency_display,
    qa_similarity,
    answer_context_similarity,
    retrieved_context_similarity,
    faithfulness,
    answer_relevancy,
    context_precision,
    context_recall,
    context_recall_note = "Requires gold reference answer (Not applicable in live interactive chat)",
    methodology = "Calculated via 384-dim semantic embeddings (all-MiniLM-L6-v2) and retrieved Qdrant context",
  } = evaluation;

  const fmtScore = (val) => {
    if (val === null || val === undefined || isNaN(val)) return "N/A";
    return `${Math.round(val * 100)}%`;
  };

  const getStatusChipClass = (st) => {
    switch (st) {
      case "completed":
        return "completed";
      case "partially_evaluated":
        return "partially_evaluated";
      case "not_evaluated":
      case "pending":
        return "not-evaluated";
      case "unavailable":
      case "failed":
      default:
        return "unavailable";
    }
  };

  return (
    <div className="eval-panel-container">
      <button
        type="button"
        className="eval-toggle-btn"
        onClick={() => setExpanded(!expanded)}
        aria-expanded={expanded}
      >
        <span className="eval-toggle-title">📊 Response Evaluation {expanded ? "▴" : "▾"}</span>
        <div className="eval-chips-compact">
          {status === "not_evaluated" && (
            <span className="eval-chip not-evaluated" title="Evaluation Status">
              Not Evaluated
            </span>
          )}
          {status === "pending" && (
            <span className="eval-chip pending" title="Evaluation Status">
              Pending
            </span>
          )}
          {(status === "unavailable" || status === "failed") && (
            <span className={`eval-chip ${getStatusChipClass(status)}`} title="Evaluation Status">
              {status.toUpperCase()}
            </span>
          )}
          {qa_similarity !== undefined && qa_similarity !== null && (
            <span className="eval-chip" title="Question–Answer Semantic Similarity">
              Q-A Sim: <strong>{fmtScore(qa_similarity)}</strong>
            </span>
          )}
          {answer_context_similarity !== undefined && answer_context_similarity !== null && (
            <span className="eval-chip" title="Answer–Context Semantic Similarity">
              Ctx Sim: <strong>{fmtScore(answer_context_similarity)}</strong>
            </span>
          )}
          {status === "partially_evaluated" && answer_context_similarity === null && (
            <span className="eval-chip partially_evaluated" title="Partial evaluation: No context passages">
              Partial
            </span>
          )}
          {end_to_end_latency_display && end_to_end_latency_display !== "N/A" && (
            <span className="eval-chip latency" title="Total End-to-End Latency">
              ⏱ {end_to_end_latency_display}
            </span>
          )}
        </div>
      </button>

      {expanded && (
        <div className="eval-details-card">
          <div className="eval-status-row">
            <span className="eval-status-label">Evaluation Status:</span>
            <span className={`eval-status-badge ${status}`}>
              {status.replace(/_/g, " ").toUpperCase()}
            </span>
          </div>

          <table className="eval-metrics-table">
            <thead>
              <tr>
                <th>Metric</th>
                <th>Score</th>
                <th>Description</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td><strong>Question–Answer Semantic Similarity</strong></td>
                <td><span className={`metric-score ${qa_similarity == null ? "neutral" : ""}`}>{fmtScore(qa_similarity)}</span></td>
                <td>Cosine similarity between user question and response embeddings.</td>
              </tr>
              <tr>
                <td><strong>Answer–Context Semantic Similarity</strong></td>
                <td><span className={`metric-score ${answer_context_similarity == null ? "neutral" : ""}`}>{fmtScore(answer_context_similarity)}</span></td>
                <td>{answer_context_similarity != null ? "Semantic grounding against retrieved Delhi environmental RAG passages." : "N/A — No RAG context passages retrieved."}</td>
              </tr>
              <tr>
                <td><strong>Retrieved-Context Similarity</strong></td>
                <td><span className={`metric-score ${retrieved_context_similarity == null ? "neutral" : ""}`}>{fmtScore(retrieved_context_similarity)}</span></td>
                <td>{retrieved_context_similarity != null ? "Vector retrieval similarity score of the top knowledge base chunk." : "N/A — No RAG context passages retrieved."}</td>
              </tr>
              <tr>
                <td><strong>Faithfulness</strong></td>
                <td><span className={`metric-score ${faithfulness == null ? "neutral" : ""}`}>{fmtScore(faithfulness)}</span></td>
                <td>{faithfulness != null ? "Claim-level factual grounding against verified context." : "N/A — Requires claim-level NLI verification; evaluated in offline benchmark suite."}</td>
              </tr>
              <tr>
                <td><strong>Answer Relevancy</strong></td>
                <td><span className={`metric-score ${answer_relevancy == null ? "neutral" : ""}`}>{fmtScore(answer_relevancy)}</span></td>
                <td>{answer_relevancy != null ? "Evaluated against reverse question generation." : "N/A — Requires reverse question generation; evaluated in offline benchmark suite."}</td>
              </tr>
              <tr>
                <td><strong>Context Precision</strong></td>
                <td><span className={`metric-score ${context_precision == null ? "neutral" : ""}`}>{fmtScore(context_precision)}</span></td>
                <td>{context_precision != null ? "Signal-to-noise ratio of retrieved knowledge passages." : "N/A — Requires ground-truth relevance annotations per chunk; evaluated in offline benchmark suite."}</td>
              </tr>
              <tr>
                <td><strong>Context Recall</strong></td>
                <td><span className="metric-score neutral">{fmtScore(context_recall)}</span></td>
                <td>{context_recall_note}</td>
              </tr>
              <tr>
                <td><strong>Generation Latency</strong></td>
                <td><span className={`metric-score ${!generation_latency_display || generation_latency_display === "N/A" ? "neutral" : ""}`}>{generation_latency_display || "N/A"}</span></td>
                <td>Time spent generating the response text.</td>
              </tr>
              <tr>
                <td><strong>End-to-End Latency</strong></td>
                <td><span className={`metric-score ${!end_to_end_latency_display || end_to_end_latency_display === "N/A" ? "neutral" : ""}`}>{end_to_end_latency_display || latency_display || "N/A"}</span></td>
                <td>Total request duration (retrieval, generation, and semantic evaluation).</td>
              </tr>
            </tbody>
          </table>

          <div className="eval-transparency-note">
            ℹ️ <strong>Evaluation Transparency:</strong> {methodology}. Scores are objective mathematical estimates, not guarantees of factual correctness. Latency measures execution time, not answer quality.
          </div>
        </div>
      )}
    </div>
  );
}

export default function AirSenseAiBotModal({ isOpen, onClose }) {
  const [messages, setMessages] = useState([
    {
      id: "initial",
      text: "Namaste! I'm 🤖 AirGuideBot, your AI Environmental Intelligence & Advisory assistant.\n\nI provide real-time Delhi NCR air quality interpretation, recommend optimal outdoor exercise windows based on diurnal inversion physics, evaluate clean commute corridors, and reference Delhi CAQM GRAP vehicle regulations. How can I help you right now?",
      isUser: false,
      timestamp: new Date(),
      evaluation: {
        status: "not_evaluated",
        latency_ms: null,
        latency_display: "N/A",
        generation_latency_ms: null,
        generation_latency_display: "N/A",
        end_to_end_latency_ms: null,
        end_to_end_latency_display: "N/A",
        qa_similarity: null,
        answer_context_similarity: null,
        retrieved_context_similarity: null,
        faithfulness: null,
        answer_relevancy: null,
        context_precision: null,
        context_recall: null,
        context_recall_note: "Requires gold reference answer (Not applicable in live interactive chat)",
        methodology: "Static system greeting (Not evaluated)",
      },
    },
  ]);
  const [input, setInput] = useState("");
  const [isTyping, setIsTyping] = useState(false);
  const messagesEndRef = useRef(null);

  const quickSuggestions = [
    "🏃 Can I jog in Lodhi Garden now?",
    "🚗 Cleanest route from CP to India Gate?",
    "👶 Precautions for children in smog?",
    "🚨 Are BS-IV diesel cars banned today?",
    "🪟 When should I open windows in Delhi?",
    "😷 What mask is best for PM2.5?",
  ];

  useEffect(() => {
    if (isOpen) {
      messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
    }
  }, [messages, isOpen]);

  if (!isOpen) return null;

  function generateFallbackResponse(q) {
    const query = q.toLowerCase();

    if (query.includes("jog") || query.includes("run") || query.includes("walk") || query.includes("exercise")) {
      return "🏃 Outdoor Exercise Guidance for Delhi:\n\n" +
        "• Recommended Window: Midday (1:00 PM – 4:30 PM). Solar thermal convection lifts ground-level particulates.\n" +
        "• High Risk Window: Early morning (5:00 AM – 8:30 AM). Surface temperature inversions trap vehicular exhaust near ground level.\n" +
        "• Best Location: Lodhi Garden or Nehru Park — typically 40–55% cleaner than arterial corridors like Ring Road or Anand Vihar.";
    }

    if (query.includes("route") || query.includes("cp") || query.includes("india gate") || query.includes("drive") || query.includes("travel")) {
      return "🚗 Smart Mobility Route Recommendation:\n\n" +
        "• Connaught Place → India Gate:\n" +
        "  Take Kasturba Gandhi Marg or Janpath rather than Barakhamba Road.\n" +
        "  Route exposure drops by ~28% less PM2.5 inhalation.\n" +
        "• Recommended Departure: Leaving after 8:15 PM avoids peak traffic idling and reduces cumulative exposure.";
    }

    if (query.includes("child") || query.includes("baby") || query.includes("infant") || query.includes("elder") || query.includes("asthma")) {
      return "👶 Sensitive Demographic Advisory (Children & Elderly):\n\n" +
        "• Lungs of children inhale 50% more air per pound of body weight than adults.\n" +
        "• Keep school commute windows sealed with air recirculation on.\n" +
        "• Ensure pediatric asthma inhalers are on hand.\n" +
        "• Avoid outdoor play near high-density traffic intersections during morning inversion peaks.";
    }

    if (query.includes("grap") || query.includes("car") || query.includes("diesel") || query.includes("bs-iv") || query.includes("ban")) {
      return "🚨 Delhi CAQM GRAP Regulatory Status:\n\n" +
        "• Stage I (201–300 AQI): Strict dust control at construction sites.\n" +
        "• Stage II (301–400 AQI): Diesel generators prohibited; elevated municipal parking fees.\n" +
        "• Stage III (401–450 AQI): BS-III petrol and BS-IV diesel cars prohibited from NCT Delhi roads (₹20,000 fine under MV Act).\n" +
        "• Stage IV (>450 AQI): Non-essential truck entry and construction activity halted.";
    }

    if (query.includes("window") || query.includes("ventilat") || query.includes("air purifier")) {
      return "🪟 Home Ventilation Protocols for Delhi:\n\n" +
        "• Keep exterior windows firmly closed between 7:30 PM and 9:30 AM (Inversion trap period).\n" +
        "• Best ventilation window: 1:30 PM to 4:00 PM when sunshine peaks and surface wind disperses smog.\n" +
        "• Run certified HEPA air purifiers in bedrooms overnight.";
    }

    if (query.includes("mask") || query.includes("n95") || query.includes("protect")) {
      return "😷 Particulate Protection Standards:\n\n" +
        "• Standard cloth or surgical masks filter less than 20% of toxic PM2.5 aerosols.\n" +
        "• Use certified N95 or FFP2 respirators with an airtight nose-bridge seal when walking outdoors in Delhi when AQI exceeds 200.";
    }

    return "🤖 AirGuideBot Environmental Telemetry Analysis:\n\n" +
      "Delhi's air quality is governed by boundary-layer mixing height and vehicular traffic volume.\n\n" +
      "Key recommendations:\n" +
      "1. Prioritize indoor activities during morning and evening rush hours.\n" +
      "2. Use the AirSense 'Plan Route' tool to compare exposure across alternative corridors.\n" +
      "3. Consider visiting green corridors (Lodhi Garden, Nehru Park) for cleaner ambient conditions.";
  }

  async function handleSend(textToSend) {
    const text = textToSend || input;
    if (!text.trim()) return;

    const userMsg = {
      id: Date.now().toString(),
      text,
      isUser: true,
      timestamp: new Date(),
    };

    setMessages((prev) => [...prev, userMsg]);
    setInput("");
    setIsTyping(true);

    const startTime = Date.now();

    try {
      // Build conversation history for context
      const chatHistory = messages.slice(-4).map((m) => ({
        role: m.isUser ? "user" : "assistant",
        content: m.text,
      }));

      const apiResult = await sendAirGuideChat({
        message: text,
        history: chatHistory,
      });

      const latencyMs = apiResult?.evaluation?.latency_ms || (Date.now() - startTime);

      const botMsg = {
        id: (Date.now() + 1).toString(),
        text: apiResult?.response || generateFallbackResponse(text),
        isUser: false,
        timestamp: new Date(),
        sources: apiResult?.sources || [],
        evaluation: apiResult?.evaluation || {
          status: "unavailable",
          latency_ms: latencyMs,
          latency_display: `${latencyMs}ms`,
          generation_latency_ms: null,
          generation_latency_display: "N/A",
          end_to_end_latency_ms: latencyMs,
          end_to_end_latency_display: `${latencyMs}ms`,
          qa_similarity: null,
          answer_context_similarity: null,
          retrieved_context_similarity: null,
          faithfulness: null,
          answer_relevancy: null,
          context_precision: null,
          context_recall: null,
          context_recall_note: "Requires gold reference answer (Not applicable in live interactive chat)",
          methodology: "Live evaluation payload was unavailable from API response",
        },
      };

      setMessages((prev) => [...prev, botMsg]);
    } catch (err) {
      console.warn("Notice: AirGuideBot live API unavailable, using verified local intelligence:", err);
      const elapsed = Date.now() - startTime;
      const fallbackText = generateFallbackResponse(text);

      const botMsg = {
        id: (Date.now() + 1).toString(),
        text: fallbackText,
        isUser: false,
        timestamp: new Date(),
        evaluation: {
          status: "unavailable",
          latency_ms: elapsed,
          latency_display: `${elapsed}ms`,
          generation_latency_ms: elapsed,
          generation_latency_display: `${elapsed}ms`,
          end_to_end_latency_ms: elapsed,
          end_to_end_latency_display: `${elapsed}ms`,
          qa_similarity: null,
          answer_context_similarity: null,
          retrieved_context_similarity: null,
          faithfulness: null,
          answer_relevancy: null,
          context_precision: null,
          context_recall: null,
          context_recall_note: "Requires gold reference answer (Not applicable in live interactive chat)",
          methodology: "Local client fallback generated when backend API was unavailable; live evaluation not performed",
        },
      };
      setMessages((prev) => [...prev, botMsg]);
    } finally {
      setIsTyping(false);
    }
  }

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal-content bot-modal" onClick={(e) => e.stopPropagation()}>
        <div className="bot-modal-header">
          <div className="bot-header-info">
            <span className="bot-avatar">🤖</span>
            <div>
              <h3 className="bot-title">AirGuideBot</h3>
              <p className="bot-status">● AI-Powered Environmental Intelligence &amp; Advisory</p>
            </div>
          </div>
          <button className="modal-close-btn" onClick={onClose}>✕</button>
        </div>

        {/* Quick Suggestion Chips */}
        <div className="bot-suggestions-strip">
          {quickSuggestions.map((q, idx) => (
            <button
              key={idx}
              className="bot-chip"
              onClick={() => handleSend(q)}
            >
              {q}
            </button>
          ))}
        </div>

        {/* Message Feed */}
        <div className="bot-messages-feed">
          {messages.map((m) => (
            <div
              key={m.id}
              className={`bot-message-row ${m.isUser ? "user-row" : "bot-row"}`}
            >
              {!m.isUser && <span className="bot-bubble-icon">🌿</span>}
              <div className={`bot-bubble ${m.isUser ? "user-bubble" : "assistant-bubble"}`}>
                <div className="bot-bubble-text" style={{ whiteSpace: "pre-line" }}>
                  {m.text}
                </div>
                <div className="bot-bubble-time">
                  {new Date(m.timestamp).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
                </div>

                {/* Compact Per-Response LLM Evaluation Panel */}
                {!m.isUser && m.evaluation && (
                  <EvaluationPanel evaluation={m.evaluation} />
                )}
              </div>
            </div>
          ))}
          {isTyping && (
            <div className="bot-message-row bot-row">
              <span className="bot-bubble-icon">🌿</span>
              <div className="bot-bubble assistant-bubble typing-bubble">
                <span className="typing-dot"></span>
                <span className="typing-dot"></span>
                <span className="typing-dot"></span>
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        {/* Input Bar */}
        <form
          className="bot-input-bar"
          onSubmit={(e) => {
            e.preventDefault();
            handleSend();
          }}
        >
          <input
            type="text"
            className="bot-input-field"
            placeholder="Ask AirGuideBot about Delhi AQI, jog windows, GRAP rules..."
            value={input}
            onChange={(e) => setInput(e.target.value)}
          />
          <button type="submit" className="bot-send-btn" disabled={!input.trim()}>
            Send ➔
          </button>
        </form>
      </div>
    </div>
  );
}
