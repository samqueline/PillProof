import { GoogleGenAI } from '@google/genai';
import OpenAI from 'openai';
import { Medicine } from '../models/medicine.model';
import { inMemoryStore } from './in_memory_store';
import mongoose from 'mongoose';

export interface ChatMessageDto {
  role: 'user' | 'model' | 'assistant';
  content: string;
}

export interface AiChatResponse {
  reply: string;
  matchedMedicines: string[];
  disclaimer: string;
}

const MEDICAL_DISCLAIMER =
  '⚠️ Medical Disclaimer: This information is for educational and awareness reference only. It does not replace clinical consultation, prescription guidance, or professional medical diagnosis. Always consult your doctor or pharmacist regarding specific health conditions and dosages.';

const SYSTEM_PROMPT = `
You are the Pill Proof AI Clinical & Pharmacological Assistant.
Your mission is to provide clear, patient-friendly, evidence-based answers regarding:
1. What the medicine is used for (indications, how it works).
2. Typical recommended dosage schedules (adult vs pediatric precautions, frequency, daily limits).
3. Important safety rules (food interactions, side effects, missed dose directions, contraindications).

SAFETY RULES:
- Always remind the user that your output is for awareness and education.
- Advise them to follow their licensed healthcare provider's or packaging instructions.
- If an overdose, allergic reaction (swelling, difficulty breathing), or poisoning is suspected, tell them to call emergency services immediately.
`;

// Built-in pharmacological knowledge base for instant answers & offline/fallback mode
const CLINICAL_KNOWLEDGE_BASE: Record<
  string,
  {
    name: string;
    uses: string;
    typicalDosage: string;
    precautions: string;
    sideEffects: string;
  }
> = {
  amoxicillin: {
    name: 'Amoxicillin',
    uses: 'Broad-spectrum penicillin antibiotic used to treat bacterial infections including ear, nose, throat, respiratory tract (bronchitis, pneumonia), urinary tract, and skin infections.',
    typicalDosage: 'Adults: Commonly 250 mg to 500 mg every 8 hours, or 500 mg to 875 mg every 12 hours depending on infection severity. Complete the full prescribed course even if symptoms resolve early.',
    precautions: 'Do not use if allergic to penicillin or beta-lactam antibiotics. Ineffective against viral infections (like colds or flu).',
    sideEffects: 'Mild diarrhea, nausea, skin rash, or upset stomach. Seek urgent care for signs of severe allergic reaction (wheezing, facial swelling).'
  },
  paracetamol: {
    name: 'Paracetamol (Acetaminophen / Dolo)',
    uses: 'Analgesic and antipyretic used to relieve mild-to-moderate pain (headache, body ache, toothache) and reduce fever.',
    typicalDosage: 'Adults: 500 mg to 650 mg every 4 to 6 hours as needed. Maximum daily limit: strictly do not exceed 4,000 mg (4 grams) in 24 hours to prevent acute liver toxicity.',
    precautions: 'Avoid combining with other cold/cough medicines containing acetaminophen. Limit alcohol consumption to protect liver health.',
    sideEffects: 'Generally well tolerated at recommended doses. High or frequent doses can cause serious liver damage.'
  },
  ibuprofen: {
    name: 'Ibuprofen (Brufen / Advil)',
    uses: 'Non-steroidal anti-inflammatory drug (NSAID) used for pain relief, reducing swelling/inflammation, and fever reduction.',
    typicalDosage: 'Adults: 200 mg to 400 mg every 4 to 6 hours after meals. Maximum OTC daily limit is usually 1,200 mg (up to 2,400 mg under strict medical supervision).',
    precautions: 'Take with food or milk to protect stomach lining. Avoid if you have active stomach ulcers, severe kidney disease, or in late pregnancy.',
    sideEffects: 'Stomach irritation, heartburn, nausea, dizziness. Long-term use can increase risk of gastrointestinal bleeding.'
  },
  metformin: {
    name: 'Metformin Hydrochloride (Glycomet)',
    uses: 'First-line oral antidiabetic medication for managing Type 2 diabetes mellitus by decreasing hepatic glucose production and improving insulin sensitivity.',
    typicalDosage: 'Adults: Typically starts at 500 mg once or twice daily with meals, titrated by physician up to 2,000 mg daily in divided doses.',
    precautions: 'Always take with or immediately after meals to reduce stomach upset. Maintain regular kidney function monitoring. Avoid excessive alcohol intake.',
    sideEffects: 'Nausea, diarrhea, abdominal discomfort, metallic taste. Rarely, lactic acidosis (seek immediate medical attention if experiencing extreme fatigue or severe muscle pain).'
  },
  atorvastatin: {
    name: 'Atorvastatin (Lipitor / Atorva)',
    uses: 'HMG-CoA reductase inhibitor (statin) used to lower LDL ("bad") cholesterol, lower triglycerides, and reduce the risk of heart attack or stroke.',
    typicalDosage: 'Adults: 10 mg to 80 mg once daily, taken at any time of day with or without food (often recommended at bedtime for consistency).',
    precautions: 'Avoid consuming large quantities of grapefruit juice. Report unexplained muscle aches or weakness immediately.',
    sideEffects: 'Headache, mild joint pain, nausea. Rare: muscle breakdown (rhabdomyolysis) or elevated liver enzymes.'
  },
  azithromycin: {
    name: 'Azithromycin (Azee / Zithromax)',
    uses: 'Macrolide antibiotic prescribed for chest infections, throat infections, sinusitis, and certain skin or sexually transmitted infections.',
    typicalDosage: 'Adults: Commonly a 3-day course (500 mg once daily) or 5-day course (500 mg on day 1, followed by 250 mg daily on days 2-5).',
    precautions: 'Take 1 hour before or 2 hours after meals (or with food if stomach upset occurs). Complete the entire course.',
    sideEffects: 'Nausea, mild diarrhea, abdominal cramps, altered taste.'
  },
  pantoprazole: {
    name: 'Pantoprazole (Pan / Pantocid)',
    uses: 'Proton pump inhibitor (PPI) that decreases stomach acid production for acid reflux (GERD), heartburn, and healing peptic ulcers.',
    typicalDosage: 'Adults: 40 mg once daily, preferably taken 30 to 60 minutes before breakfast.',
    precautions: 'Do not crush or chew delayed-release tablets. Long-term continuous use should be monitored by your healthcare provider.',
    sideEffects: 'Headache, diarrhea, dizziness, abdominal discomfort.'
  },
  cetirizine: {
    name: 'Cetirizine (Cetzine / Zyrtec)',
    uses: 'Second-generation antihistamine used to relieve allergy symptoms such as sneezing, runny nose, itchy watery eyes, and hives.',
    typicalDosage: 'Adults and children 12+: 10 mg once daily (or 5 mg twice daily), commonly taken in the evening.',
    precautions: 'May cause mild drowsiness in some individuals; avoid operating heavy machinery until you know how it affects you.',
    sideEffects: 'Mild drowsiness, dry mouth, tiredness, headache.'
  }
};

export class AiChatService {
  /**
   * Processes a medical query and returns clinical answers with dosage, uses, and precautions.
   */
  public static async answerQuery(
    userPrompt: string,
    history: ChatMessageDto[] = []
  ): Promise<AiChatResponse> {
    const trimmed = userPrompt.trim();
    const lowerPrompt = trimmed.toLowerCase();

    // 1. Search verified database for matching medicines
    const matchedMeds: string[] = [];
    let dbContext = '';

    try {
      const searchTerms = lowerPrompt
        .split(/[\s,?.!]+/)
        .filter((w) => w.length >= 3 && !['what', 'when', 'dose', 'drug', 'take', 'with', 'used'].includes(w));

      if (searchTerms.length > 0) {
        let foundMeds: any[] = [];
        if (mongoose.connection.readyState === 1) {
          foundMeds = await Medicine.find({
            $or: [
              { brandName: { $regex: searchTerms.join('|'), $options: 'i' } },
              { genericName: { $regex: searchTerms.join('|'), $options: 'i' } }
            ]
          }).limit(3);
        } else {
          foundMeds = inMemoryStore.getMedicines().filter((m: any) =>
            searchTerms.some(
              (term) =>
                m.brandName.toLowerCase().includes(term) ||
                m.genericName.toLowerCase().includes(term)
            )
          );
        }

        if (foundMeds.length > 0) {
          matchedMeds.push(...foundMeds.map((m) => `${m.brandName} (${m.dosageStrength})`));
          dbContext =
            'Pill Proof Verified Database Records:\n' +
            foundMeds
              .map((m) => `- ${m.brandName} (Active: ${m.genericName}, Strength: ${m.dosageStrength}, Form: ${m.dosageForm}, Mfr: ${m.manufacturer})`)
              .join('\n');
        }
      }
    } catch (_) {}

    // 2. Try OpenAI API if key is available
    const openAiKey = process.env.OPENAI_API_KEY;
    if (openAiKey && openAiKey.trim().length > 15) {
      try {
        const openai = new OpenAI({ apiKey: openAiKey });
        const messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
          {
            role: 'system',
            content: `${SYSTEM_PROMPT}\n${dbContext ? '\n' + dbContext : ''}`
          }
        ];

        for (const h of history.slice(-6)) {
          messages.push({
            role: h.role === 'user' ? 'user' : 'assistant',
            content: h.content
          });
        }

        messages.push({
          role: 'user',
          content: trimmed
        });

        const completion = await openai.chat.completions.create({
          model: 'gpt-4o-mini',
          messages,
          temperature: 0.2,
          max_tokens: 600
        });

        const reply = completion.choices[0]?.message?.content;
        if (reply && reply.trim().length > 0) {
          return {
            reply: reply.trim(),
            matchedMedicines: matchedMeds,
            disclaimer: MEDICAL_DISCLAIMER
          };
        }
      } catch (err) {
        // Fall back gracefully to Gemini or local clinical knowledge base
      }
    }

    // 3. Try Google Gemini API if key is available
    const apiKey = process.env.GEMINI_API_KEY;
    if (apiKey && apiKey.trim().length > 10) {
      try {
        const ai = new GoogleGenAI({ apiKey });
        const contents = [
          {
            role: 'user',
            parts: [
              {
                text: `${SYSTEM_PROMPT}\n${dbContext ? dbContext + '\n\n' : ''}User Question: ${trimmed}`
              }
            ]
          }
        ];

        const response = await ai.models.generateContent({
          model: 'gemini-2.5-flash',
          contents
        });

        const replyText = response.text || '';
        if (replyText.trim().length > 0) {
          return {
            reply: replyText.trim(),
            matchedMedicines: matchedMeds,
            disclaimer: MEDICAL_DISCLAIMER
          };
        }
      } catch (err) {
        // Fall back gracefully to built-in clinical reference
      }
    }

    // 3. Built-in Clinical Knowledge Engine Fallback
    const fallbackReply = this._generateClinicalFallback(lowerPrompt, trimmed, dbContext);

    return {
      reply: fallbackReply,
      matchedMedicines: matchedMeds,
      disclaimer: MEDICAL_DISCLAIMER
    };
  }

  private static _generateClinicalFallback(
    lowerPrompt: string,
    rawPrompt: string,
    dbContext: string
  ): string {
    // Check if prompt matches any known drug in knowledge base
    for (const [key, info] of Object.entries(CLINICAL_KNOWLEDGE_BASE)) {
      if (lowerPrompt.includes(key) || (key === 'paracetamol' && (lowerPrompt.includes('dolo') || lowerPrompt.includes('crocin') || lowerPrompt.includes('calpol')))) {
        let answer = `### 💊 ${info.name}\n\n`;
        answer += `**What it is used for:**\n${info.uses}\n\n`;
        answer += `**Recommended / Standard Dosage:**\n${info.typicalDosage}\n\n`;
        answer += `**Important Precautions:**\n${info.precautions}\n\n`;
        answer += `**Common Side Effects:**\n${info.sideEffects}\n`;

        if (dbContext) {
          answer += `\n---\n*Matched against ${dbContext}*`;
        }

        return answer;
      }
    }

    // Check for general dosage query
    if (lowerPrompt.includes('dosage') || lowerPrompt.includes('dose') || lowerPrompt.includes('how much')) {
      return (
        `### 📋 Medication Dosage Guidance\n\n` +
        `Prescription and over-the-counter dosages depend strictly on:\n` +
        `1. **Active Ingredient & Formulation:** Whether it is immediate-release, extended-release, tablet, or liquid.\n` +
        `2. **Patient Profile:** Age, weight, kidney/liver function, and underlying conditions.\n` +
        `3. **Clinical Indication:** Specific condition being treated.\n\n` +
        `**Safety Rules:**\n` +
        `- Never exceed the daily prescribed limit configured in your Pill Proof schedule.\n` +
        `- Do not double up on doses if you miss a scheduled intake.\n` +
        `- Check the package label or ask your pharmacist for exact instructions for your specific brand.`
      );
    }

    // Check for drug interaction / safety query
    if (lowerPrompt.includes('interaction') || lowerPrompt.includes('together') || lowerPrompt.includes('with food')) {
      return (
        `### ⚠️ Drug Interactions & Safety Guidelines\n\n` +
        `- **Combining Painkillers:** Avoid taking multiple medications containing acetaminophen (Paracetamol) concurrently to prevent liver toxicity. Do not combine two NSAIDs (e.g. Ibuprofen + Naproxen).\n` +
        `- **Food & Alcohol:** NSAIDs should be taken with or after meals to prevent stomach irritation. Avoid alcohol with antibiotics and sedatives.\n` +
        `- **Timing:** Space antacids 2 hours apart from antibiotics (like Amoxicillin or Azithromycin) to maintain proper absorption.\n\n` +
        `Always consult your pharmacist or physician before combining multiple prescriptions.`
      );
    }

    // General response
    return (
      `### 🩺 Pill Proof Medicine Advisor\n\n` +
      `I can provide detailed clinical information on **what a medicine is used for**, its **standard recommended dosage**, and **safety precautions**.\n\n` +
      `**Try asking about specific medicines like:**\n` +
      `- *"What is Amoxicillin used for and what is the typical dosage?"*\n` +
      `- *"Paracetamol 650mg maximum daily dose"* \n` +
      `- *"Can I take Ibuprofen with food?"*\n` +
      `- *"What are the side effects of Metformin?"*\n` +
      `- *"When should I take Pantoprazole 40mg?"*`
    );
  }
}
