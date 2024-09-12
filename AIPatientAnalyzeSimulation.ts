import { ethers } from 'ethers';

// Simula os dados que estariam no NFT
interface PatientData {
  age: number;
  lastCheckup: Date;
  chronicConditions: string[];
  recentExams: {
    name: string;
    value: number;
    date: Date;
  }[];
}

// Simula o resultado da IA
interface AIResult {
  riskScore: number;
  priorityLevel: 'Low' | 'Medium' | 'High' | 'Critical';
  explanation: string[];
}

class HealthGuardianAI {
  private riskThresholds = {
    Low: 0.25,
    Medium: 0.5,
    High: 0.75,
  };

  // Simula o pré-processamento dos dados
  private preprocessData(data: PatientData): number[] {
    const now = new Date();
    const daysSinceLastCheckup = (now.getTime() - data.lastCheckup.getTime()) / (1000 * 3600 * 24);
    const numChronicConditions = data.chronicConditions.length;
    const avgExamValue = data.recentExams.reduce((sum, exam) => sum + exam.value, 0) / data.recentExams.length;

    return [data.age, daysSinceLastCheckup, numChronicConditions, avgExamValue];
  }

  // Simula o modelo XGBoost
  private simulateXGBoost(features: number[]): number {
    // Esta é uma simplificação extrema. Um modelo XGBoost real seria muito mais complexo.
    const weights = [0.01, 0.005, 0.1, 0.02];
    return features.reduce((sum, feature, index) => sum + feature * weights[index], 0);
  }

  // Determina o nível de prioridade com base no score de risco
  private getPriorityLevel(riskScore: number): 'Low' | 'Medium' | 'High' | 'Critical' {
    if (riskScore < this.riskThresholds.Low) return 'Low';
    if (riskScore < this.riskThresholds.Medium) return 'Medium';
    if (riskScore < this.riskThresholds.High) return 'High';
    return 'Critical';
  }

  // Gera explicações simples para o resultado
  private generateExplanation(data: PatientData, riskScore: number): string[] {
    const explanations: string[] = [];
    if (data.age > 60) explanations.push("Age is a contributing factor to risk.");
    if (data.chronicConditions.length > 0) explanations.push("Presence of chronic conditions increases risk.");
    if (new Date().getTime() - data.lastCheckup.getTime() > 365 * 24 * 60 * 60 * 1000) {
      explanations.push("It's been over a year since the last checkup.");
    }
    return explanations;
  }

  // Método principal que será chamado pelo smart contract via Chainlink
  public async analyzePatientData(encryptedData: string): Promise<AIResult> {
    // Simulando a descriptografia dos dados
    const decryptedData: PatientData = JSON.parse(ethers.utils.toUtf8String(encryptedData));

    const preprocessedData = this.preprocessData(decryptedData);
    const riskScore = this.simulateXGBoost(preprocessedData);
    const priorityLevel = this.getPriorityLevel(riskScore);
    const explanation = this.generateExplanation(decryptedData, riskScore);

    return {
      riskScore,
      priorityLevel,
      explanation,
    };
  }
}

// Simulação de uso
async function simulateAIAnalysis() {
  const ai = new HealthGuardianAI();

  // Simula dados encriptados de um paciente
  const patientData: PatientData = {
    age: 65,
    lastCheckup: new Date('2022-01-01'),
    chronicConditions: ['Diabetes', 'Hypertension'],
    recentExams: [
      { name: 'Blood Pressure', value: 150, date: new Date('2023-05-01') },
      { name: 'Blood Sugar', value: 180, date: new Date('2023-05-01') },
    ],
  };

  const encryptedData = ethers.utils.hexlify(ethers.utils.toUtf8Bytes(JSON.stringify(patientData)));

  const result = await ai.analyzePatientData(encryptedData);
  console.log('AI Analysis Result:', result);
}

simulateAIAnalysis();
