'use client';

import { useParams } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import { formatDate, formatCurrency } from '@/lib/utils';

// Mock data - replace with actual contract calls
export default function ProjectDetailPage() {
  const { id } = useParams();
  
  // This would be replaced with actual contract calls
  const { data: project, isLoading } = useQuery({
    queryKey: ['project', id],
    queryFn: async () => {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 500));
      
      // Mock data - replace with actual contract data
      return {
        id,
        name: 'SuiSwap',
        symbol: 'SSWAP',
        description: 'A decentralized exchange built on the Sui blockchain with low fees and high throughput.',
        tokenPrice: 0.1,
        totalRaised: 1250000,
        target: 2000000,
        startTime: Date.now() - 3 * 24 * 60 * 60 * 1000, // 3 days ago
        endTime: Date.now() + 7 * 24 * 60 * 60 * 1000, // 7 days from now
        status: 'live',
        website: 'https://suiswap.xyz',
        whitepaper: 'https://suiswap.xyz/whitepaper',
        socials: {
          twitter: 'suiswap',
          telegram: 'suiswap_official',
          discord: 'suiswap',
        },
        allocation: {
          personal: 500,
          total: 1000000,
          tokenAllocation: 5000,
          claimed: false,
          refunded: false,
        },
        kycRequired: true,
        kycVerified: true,
      };
    },
  });

  if (isLoading) {
    return (
      <div className="container py-12">
        <div className="animate-pulse space-y-8">
          <div className="h-10 bg-muted rounded w-1/3"></div>
          <div className="grid md:grid-cols-3 gap-8">
            <div className="md:col-span-2 space-y-6">
              <div className="h-64 bg-muted rounded-lg"></div>
              <div className="space-y-4">
                <div className="h-6 bg-muted rounded w-3/4"></div>
                <div className="h-4 bg-muted rounded w-1/2"></div>
                <div className="h-4 bg-muted rounded w-2/3"></div>
              </div>
            </div>
            <div className="space-y-6">
              <div className="h-12 bg-muted rounded"></div>
              <div className="h-32 bg-muted rounded"></div>
            </div>
          </div>
        </div>
      </div>
    );
  }


  if (!project) {
    return (
      <div className="container py-12 text-center">
        <h1 className="text-2xl font-bold mb-4">Project not found</h1>
        <p className="text-muted-foreground">The project you're looking for doesn't exist or has been removed.</p>
      </div>
    );
  }

  const progress = Math.min((project.totalRaised / project.target) * 100, 100);
  const isActive = project.status === 'live';
  const hasEnded = new Date(project.endTime) < new Date();
  const hasStarted = new Date(project.startTime) < new Date();

  return (
    <div className="container py-12">
      <div className="mb-8">
        <h1 className="text-3xl font-bold tracking-tight">{project.name} ({project.symbol})</h1>
        <p className="text-muted-foreground mt-2">
          {hasEnded 
            ? 'Sale ended on ' + formatDate(project.endTime)
            : hasStarted 
              ? 'Sale ends in ' + formatDate(project.endTime)
              : 'Sale starts ' + formatDate(project.startTime)}
        </p>
      </div>

      <div className="grid md:grid-cols-3 gap-8">
        <div className="md:col-span-2 space-y-8">
          <div className="bg-card rounded-lg border p-6">
            <h2 className="text-xl font-semibold mb-4">About the Project</h2>
            <p className="text-muted-foreground mb-6">{project.description}</p>
            
            <h3 className="font-semibold mb-2">Project Links</h3>
            <div className="flex flex-wrap gap-4">
              <a 
                href={project.website} 
                target="_blank" 
                rel="noopener noreferrer"
                className="inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium hover:bg-accent hover:text-accent-foreground"
              >
                Website
              </a>
              <a 
                href={project.whitepaper} 
                target="_blank" 
                rel="noopener noreferrer"
                className="inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium hover:bg-accent hover:text-accent-foreground"
              >
                Whitepaper
              </a>
              <a 
                href={`https://twitter.com/${project.socials.twitter}`} 
                target="_blank" 
                rel="noopener noreferrer"
                className="inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium hover:bg-accent hover:text-accent-foreground"
              >
                Twitter
              </a>
              <a 
                href={`https://t.me/${project.socials.telegram}`} 
                target="_blank" 
                rel="noopener noreferrer"
                className="inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium hover:bg-accent hover:text-accent-foreground"
              >
                Telegram
              </a>
            </div>
          </div>

          <div className="bg-card rounded-lg border p-6">
            <h2 className="text-xl font-semibold mb-4">Token Metrics</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Token Price</span>
                  <span>{formatCurrency(project.tokenPrice)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Total Tokens</span>
                  <span>{(project.target / project.tokenPrice).toLocaleString()} {project.symbol}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Tokens for Sale</span>
                  <span>{(project.target / project.tokenPrice).toLocaleString()} {project.symbol}</span>
                </div>
              </div>
              <div className="space-y-2">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Sale Start</span>
                  <span>{formatDate(project.startTime)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Sale End</span>
                  <span>{formatDate(project.endTime)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Accepting</span>
                  <span>SUI</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div className="space-y-6">
          <div className="bg-card rounded-lg border p-6">
            <h2 className="text-xl font-semibold mb-4">Sale Progress</h2>
            <div className="space-y-4">
              <div>
                <div className="flex justify-between text-sm mb-1">
                  <span className="text-muted-foreground">Progress</span>
                  <span>{progress.toFixed(1)}%</span>
                </div>
                <div className="h-2 bg-muted rounded-full overflow-hidden">
                  <div 
                    className="h-full bg-primary" 
                    style={{ width: `${progress}%` }}
                  />
                </div>
                <div className="flex justify-between text-sm mt-2">
                  <span className="text-muted-foreground">{formatCurrency(project.totalRaised)} raised</span>
                  <span>of {formatCurrency(project.target)}</span>
                </div>
              </div>

              {project.allocation && (
                <div className="pt-4 border-t">
                  <h3 className="font-medium mb-2">Your Allocation</h3>
                  <div className="space-y-2">
                    <div className="flex justify-between text-sm">
                      <span className="text-muted-foreground">Contributed</span>
                      <span>{formatCurrency(project.allocation.personal)} SUI</span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-muted-foreground">Token Allocation</span>
                      <span>{project.allocation.tokenAllocation.toLocaleString()} {project.symbol}</span>
                    </div>
                    <div className="pt-2">
                      <button 
                        className={`w-full inline-flex items-center justify-center rounded-md px-4 py-2 text-sm font-medium ${
                          hasEnded 
                            ? project.allocation.claimed 
                              ? 'bg-gray-100 text-gray-400 cursor-not-allowed' 
                              : 'bg-primary text-primary-foreground hover:bg-primary/90'
                            : !isActive || hasEnded || (project.kycRequired && !project.kycVerified)
                              ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                              : 'bg-primary text-primary-foreground hover:bg-primary/90'
                        }`}
                        disabled={
                          hasEnded 
                            ? project.allocation.claimed 
                            : !isActive || hasEnded || (project.kycRequired && !project.kycVerified)
                        }
                      >
                        {hasEnded 
                          ? project.allocation.claimed 
                            ? 'Tokens Claimed' 
                            : 'Claim Tokens'
                          : !project.kycVerified && project.kycRequired 
                            ? 'KYC Required' 
                            : isActive 
                              ? 'Contribute Now' 
                              : 'Sale Not Started'}
                      </button>
                      {project.kycRequired && !project.kycVerified && (
                        <p className="text-xs text-muted-foreground mt-2 text-center">
                          KYC verification is required to participate
                        </p>
                      )}
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>

          {project.kycRequired && (
            <div className="bg-card rounded-lg border p-6">
              <h2 className="text-xl font-semibold mb-4">KYC Verification</h2>
              <div className="space-y-4">
                <div className={`p-3 rounded-md ${project.kycVerified ? 'bg-green-50 dark:bg-green-900/20' : 'bg-yellow-50 dark:bg-yellow-900/20'}`}>
                  <div className="flex items-center">
                    <div className="flex-shrink-0">
                      {project.kycVerified ? (
                        <svg className="h-5 w-5 text-green-400" viewBox="0 0 20 20" fill="currentColor">
                          <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                        </svg>
                      ) : (
                        <svg className="h-5 w-5 text-yellow-400" viewBox="0 0 20 20" fill="currentColor">
                          <path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                        </svg>
                      )}
                    </div>
                    <div className="ml-3">
                      <p className={`text-sm font-medium ${project.kycVerified ? 'text-green-800 dark:text-green-200' : 'text-yellow-800 dark:text-yellow-200'}`}>
                        {project.kycVerified ? 'KYC Verified' : 'KYC Not Verified'}
                      </p>
                      <p className="text-xs text-muted-foreground mt-1">
                        {project.kycVerified 
                          ? 'Your identity has been verified for this sale.'
                          : 'Complete KYC to participate in this sale.'}
                      </p>
                    </div>
                  </div>
                </div>
                {!project.kycVerified && (
                  <button className="w-full inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium hover:bg-accent hover:text-accent-foreground">
                    Verify KYC
                  </button>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
