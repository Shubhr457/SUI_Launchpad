import Image from "next/image";
import Link from "next/link";
import { ProjectCard } from "@/components/ProjectCard";

// Mock data for featured projects
const featuredProjects = [
  {
    id: '1',
    name: 'SuiSwap',
    symbol: 'SSWAP',
    description: 'A decentralized exchange built on the Sui blockchain with low fees and high throughput.',
    tokenPrice: 0.1,
    totalRaised: 1250000,
    target: 2000000,
    startTime: Date.now() - 3 * 24 * 60 * 60 * 1000, // 3 days ago
    endTime: Date.now() + 7 * 24 * 60 * 60 * 1000, // 7 days from now
    status: 'live' as const,
    kycRequired: true,
  },
  {
    id: '2',
    name: 'SuiLend',
    symbol: 'SLEND',
    description: 'A decentralized lending protocol on Sui enabling users to earn interest on deposits and borrow assets.',
    tokenPrice: 0.25,
    totalRaised: 3500000,
    target: 5000000,
    startTime: Date.now() + 2 * 24 * 60 * 60 * 1000, // 2 days from now
    endTime: Date.now() + 14 * 24 * 60 * 60 * 1000, // 14 days from now
    status: 'upcoming' as const,
    kycRequired: false,
  },
  {
    id: '3',
    name: 'SuiPunks',
    symbol: 'PUNK',
    description: 'Unique digital collectibles on the Sui blockchain. Each SuiPunk is unique and generated algorithmically.',
    tokenPrice: 50,
    totalRaised: 1000000,
    target: 1000000,
    startTime: Date.now() - 14 * 24 * 60 * 60 * 1000, // 14 days ago
    endTime: Date.now() - 7 * 24 * 60 * 60 * 1000, // 7 days ago
    status: 'ended' as const,
    kycRequired: true,
  },
];

export default function Home() {
  return (
    <div className="flex flex-col min-h-screen">
      {/* Hero Section */}
      <section className="container mx-auto py-16 px-4 md:py-24">
        <div className="max-w-4xl mx-auto">
          <div className="flex flex-col gap-8 items-center text-center md:items-start md:text-left">
            <Image
              className="dark:invert"
              src="/next.svg"
              alt="Sui Launchpad"
              width={180}
              height={40}
              priority
            />
            <h1 className="text-4xl md:text-5xl font-bold tracking-tight">
              Discover the next big thing on Sui
            </h1>
            <p className="text-xl text-muted-foreground max-w-2xl">
              Participate in Initial DEX Offerings (IDOs) of the most promising projects building on the Sui blockchain.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 w-full sm:w-auto">
              <Link 
                href="/projects" 
                className="inline-flex items-center justify-center rounded-md bg-primary px-6 py-3 text-sm font-medium text-primary-foreground hover:bg-primary/90 transition-colors"
              >
                Explore Projects
              </Link>
              <Link 
                href="#how-it-works" 
                className="inline-flex items-center justify-center rounded-md border border-input bg-background px-6 py-3 text-sm font-medium hover:bg-accent hover:text-accent-foreground transition-colors"
              >
                How It Works
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Featured Projects */}
      <section className="container mx-auto py-16 px-4">
        <div className="max-w-7xl mx-auto">
          <div className="flex justify-between items-center mb-8">
            <h2 className="text-2xl md:text-3xl font-bold tracking-tight">Featured Projects</h2>
            <Link href="/projects" className="text-sm font-medium text-primary hover:underline">
              View all projects →
            </Link>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {featuredProjects.map((project) => (
              <Link key={project.id} href={`/projects/${project.id}`} className="block h-full">
                <ProjectCard {...project} />
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* How It Works */}
      <section id="how-it-works" className="container mx-auto py-16 px-4 bg-background/50">
        <div className="max-w-5xl mx-auto">
          <h2 className="text-2xl md:text-3xl font-bold tracking-tight text-center mb-12">How It Works</h2>
          
          <div className="grid md:grid-cols-3 gap-8 md:gap-12">          
            <div className="flex flex-col items-center text-center">
              <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mb-6">
                <span className="text-2xl font-bold text-primary">1</span>
              </div>
              <h3 className="text-xl font-semibold mb-3">Connect Wallet</h3>
              <p className="text-muted-foreground">Connect your Sui-compatible wallet to get started with the platform.</p>
            </div>
            
            <div className="flex flex-col items-center text-center">
              <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mb-6">
                <span className="text-2xl font-bold text-primary">2</span>
              </div>
              <h3 className="text-xl font-semibold mb-3">Choose a Project</h3>
              <p className="text-muted-foreground">Browse and select from a variety of vetted IDO projects.</p>
            </div>
            
            <div className="flex flex-col items-center text-center">
              <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mb-6">
                <span className="text-2xl font-bold text-primary">3</span>
              </div>
              <h3 className="text-xl font-semibold mb-3">Participate</h3>
              <p className="text-muted-foreground">Contribute to the IDO and receive tokens upon successful completion.</p>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="container mx-auto py-16 px-4 mb-16">
        <div className="max-w-4xl mx-auto bg-muted/50 rounded-2xl py-12 px-6 text-center">
          <h2 className="text-2xl md:text-3xl font-bold tracking-tight mb-4">Ready to Launch Your Project?</h2>
          <p className="text-muted-foreground max-w-2xl mx-auto mb-8">
            Join the Sui ecosystem and launch your token with our secure and efficient launchpad platform.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link 
              href="/launch" 
              className="inline-flex items-center justify-center rounded-md bg-primary px-6 py-3 text-sm font-medium text-primary-foreground hover:bg-primary/90 transition-colors"
            >
              Apply for IDO
            </Link>
            <Link 
              href="/docs" 
              className="inline-flex items-center justify-center rounded-md border border-input bg-background px-6 py-3 text-sm font-medium hover:bg-accent hover:text-accent-foreground transition-colors"
            >
              Read Documentation
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
}
