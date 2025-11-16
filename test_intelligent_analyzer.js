/**
 * Test script for the intelligent performance analysis framework
 * Tests the newly implemented framework with real user code
 */

import { intelligentAnalyzer } from './frontend/backend/src/services/intelligentAnalyzer.js';
import fs from 'fs/promises';

// Load the test user code
const testCode = await fs.readFile('./test_user_code.py', 'utf-8');

console.log('🧪 Testing Intelligent Performance Analysis Framework\n');
console.log('📝 User Code to Analyze:');
console.log('-'.repeat(50));
console.log(testCode);
console.log('-'.repeat(50));

async function runTests() {
  try {
    console.log('\n🔍 Running Architecture Detection Test...');
    
    // Test 1: Architecture Pattern Detection
    const analysis = await intelligentAnalyzer.analyzeCode(testCode);
    
    console.log('\n📊 Architecture Analysis Results:');
    console.log('Type:', analysis.architecture.type);
    console.log('Confidence:', analysis.architecture.confidence);
    console.log('Detected Features:', analysis.architecture.detectedFeatures);
    console.log('Imports:', analysis.architecture.imports);
    
    // Test 2: Educational Insights
    console.log('\n🎓 Educational Insights:');
    analysis.insights.forEach((insight, index) => {
      console.log(`${index + 1}. [${insight.type.toUpperCase()}] ${insight.title}`);
      console.log(`   Description: ${insight.description}`);
      console.log(`   Recommendation: ${insight.recommendation || 'None'}`);
      console.log(`   Severity: ${insight.severity}`);
      console.log('');
    });
    
    // Test 3: Performance Metrics
    console.log('⚡ Performance Metrics:');
    console.log('Memory Usage:', analysis.performanceMetrics?.estimatedMemoryUsage);
    console.log('Concurrency:', analysis.performanceMetrics?.estimatedConcurrency);
    console.log('Scalability Rating:', analysis.performanceMetrics?.scalabilityRating);
    
    // Test 4: Recommended Tests
    console.log('\n🧪 Recommended Test Scenarios:');
    analysis.recommendedTests.forEach((test, index) => {
      console.log(`${index + 1}. ${test.name} (${test.testType})`);
      console.log(`   Description: ${test.description}`);
      console.log(`   Parameters:`, test.parameters);
      console.log('');
    });
    
    // Test 5: Run a Performance Test
    console.log('🚀 Running Baseline Performance Test...');
    const baselineTest = analysis.recommendedTests.find(t => t.name.includes('Baseline'));
    if (baselineTest) {
      const testResult = await intelligentAnalyzer.executePerformanceTest(testCode, baselineTest);
      console.log('✅ Performance Test Result:');
      console.log('Success:', testResult.success);
      console.log('Metrics:', testResult.metrics);
      if (testResult.error) console.log('Error:', testResult.error);
    }
    
    // Verification Summary
    console.log('\n📋 VERIFICATION SUMMARY:');
    console.log('='.repeat(50));
    
    // Check expected features
    const expectedChecks = [
      {
        name: 'Architecture Detection (in-memory)',
        passed: analysis.architecture.type === 'in-memory',
        actual: analysis.architecture.type
      },
      {
        name: 'Detected Global Dictionaries',
        passed: analysis.insights.some(i => i.title.includes('Global Dictionary')),
        actual: analysis.insights.filter(i => i.title.includes('Global Dictionary')).length
      },
      {
        name: 'Detected datetime.now() Issues',
        passed: analysis.insights.some(i => i.title.includes('datetime.now')),
        actual: analysis.insights.filter(i => i.title.includes('datetime.now')).length
      },
      {
        name: 'Appropriate Test Selection',
        passed: analysis.recommendedTests.some(t => t.testType === 'memory'),
        actual: analysis.recommendedTests.map(t => t.testType).join(', ')
      },
      {
        name: 'Educational Value',
        passed: analysis.insights.length >= 3,
        actual: `${analysis.insights.length} insights provided`
      }
    ];
    
    expectedChecks.forEach(check => {
      const status = check.passed ? '✅ PASS' : '❌ FAIL';
      console.log(`${status} ${check.name}: ${check.actual}`);
    });
    
    const overallSuccess = expectedChecks.every(check => check.passed);
    console.log('\n🏆 Overall Result:', overallSuccess ? '✅ SUCCESS' : '❌ NEEDS DEBUGGING');
    
    if (!overallSuccess) {
      console.log('\n🔧 Issues that need debugging:');
      expectedChecks.filter(check => !check.passed).forEach(check => {
        console.log(`- ${check.name}: Expected different result than "${check.actual}"`);
      });
    }
    
  } catch (error) {
    console.error('❌ Test failed with error:', error.message);
    console.error('Stack trace:', error.stack);
  }
}

// Run the tests
runTests();